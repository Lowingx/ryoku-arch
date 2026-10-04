#include "systemmonitor.hpp"

#include <QByteArray>
#include <QByteArrayView>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLibrary>
#include <QMetaObject>
#include <QSet>
#include <QStringList>
#include <QVector>

#include <algorithm>
#include <charconv>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstring>
#include <limits>
#include <mutex>
#include <utility>
#include <pwd.h>
#include <sys/statvfs.h>
#include <unistd.h>

namespace {

using Clock = std::chrono::steady_clock;
constexpr double BytesPerGiB = 1024.0 * 1024.0 * 1024.0;

qint64 monotonicMilliseconds() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now().time_since_epoch()).count();
}

QByteArray readSmallFile(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return file.read(16384);
}

quint64 readUnsignedFile(const QString& path) {
    bool ok = false;
    const quint64 value = readSmallFile(path).trimmed().toULongLong(&ok);
    return ok ? value : 0;
}

QString readTextFile(const QString& path) {
    return QString::fromUtf8(readSmallFile(path)).trimmed();
}

QString ueventField(const QString& devicePath, const QByteArray& key) {
    const QByteArray contents = readSmallFile(devicePath + QStringLiteral("/uevent"));
    const QByteArray prefix = key + '=';
    qsizetype offset = 0;
    while (offset < contents.size()) {
        const qsizetype end = contents.indexOf('\n', offset);
        const qsizetype length = (end < 0 ? contents.size() : end) - offset;
        const QByteArrayView line(contents.constData() + offset, length);
        if (line.startsWith(prefix))
            return QString::fromUtf8(line.sliced(prefix.size()));
        if (end < 0)
            break;
        offset = end + 1;
    }
    return {};
}

QString cpuModelName() {
    QFile file(QStringLiteral("/proc/cpuinfo"));
    if (!file.open(QIODevice::ReadOnly))
        return {};
    QByteArray line;
    while (!(line = file.readLine()).isEmpty()) {
        const qsizetype colon = line.indexOf(':');
        if (colon < 0)
            continue;
        const QByteArray key = line.first(colon).trimmed();
        if (key == "model name" || key == "Hardware" || key == "Processor")
            return QString::fromUtf8(line.sliced(colon + 1)).trimmed();
    }
    return {};
}

QString currentUserName() {
    passwd entry{};
    passwd* result = nullptr;
    std::array<char, 16384> buffer{};
    if (getpwuid_r(geteuid(), &entry, buffer.data(), buffer.size(), &result) == 0 && result && result->pw_name)
        return QString::fromLocal8Bit(result->pw_name);
    return qEnvironmentVariable("USER");
}

QString currentHostName() {
    std::array<char, 256> name{};
    if (gethostname(name.data(), name.size() - 1) != 0)
        return {};
    name.back() = '\0';
    return QString::fromLocal8Bit(name.data());
}

struct CpuTotals {
    quint64 total = 0;
    quint64 idle = 0;
    bool valid = false;
};

CpuTotals readCpuTotals() {
    QFile file(QStringLiteral("/proc/stat"));
    if (!file.open(QIODevice::ReadOnly))
        return {};
    const QList<QByteArray> fields = file.readLine().simplified().split(' ');
    if (fields.size() < 5 || fields[0] != "cpu")
        return {};

    std::array<quint64, 8> values{};
    const int count = std::min<int>(values.size(), fields.size() - 1);
    for (int i = 0; i < count; ++i) {
        bool ok = false;
        values[i] = fields[i + 1].toULongLong(&ok);
        if (!ok)
            return {};
    }

    CpuTotals out;
    for (int i = 0; i < count; ++i)
        out.total += values[i];
    out.idle = values[3] + (count > 4 ? values[4] : 0);
    out.valid = true;
    return out;
}

struct MemoryReading {
    double usedGiB = 0.0;
    double totalGiB = 0.0;
    double percent = 0.0;
    bool available = false;
};

MemoryReading readMemory() {
    const QByteArray bytes = readSmallFile(QStringLiteral("/proc/meminfo"));
    quint64 totalKiB = 0;
    quint64 availableKiB = 0;
    quint64 freeKiB = 0;
    quint64 buffersKiB = 0;
    quint64 cachedKiB = 0;
    bool availableKnown = false;
    qsizetype offset = 0;
    while (offset < bytes.size()) {
        const qsizetype newline = bytes.indexOf('\n', offset);
        const qsizetype end = newline < 0 ? bytes.size() : newline;
        const qsizetype colon = bytes.indexOf(':', offset);
        if (colon >= offset && colon < end) {
            const QByteArrayView key(bytes.constData() + offset, colon - offset);
            const char* first = bytes.constData() + colon + 1;
            const char* last = bytes.constData() + end;
            while (first < last && (*first == ' ' || *first == '\t'))
                ++first;
            quint64 value = 0;
            if (std::from_chars(first, last, value).ec == std::errc{}) {
                if (key == "MemTotal")
                    totalKiB = value;
                else if (key == "MemAvailable") {
                    availableKiB = value;
                    availableKnown = true;
                } else if (key == "MemFree")
                    freeKiB = value;
                else if (key == "Buffers")
                    buffersKiB = value;
                else if (key == "Cached")
                    cachedKiB = value;
            }
        }
        offset = end + 1;
    }
    if (totalKiB == 0)
        return {};
    if (!availableKnown)
        availableKiB = std::min(totalKiB, freeKiB + buffersKiB + cachedKiB);

    const quint64 usedKiB = totalKiB - std::min(totalKiB, availableKiB);
    MemoryReading out;
    out.usedGiB = static_cast<double>(usedKiB) * 1024.0 / BytesPerGiB;
    out.totalGiB = static_cast<double>(totalKiB) * 1024.0 / BytesPerGiB;
    out.percent = 100.0 * static_cast<double>(usedKiB) / static_cast<double>(totalKiB);
    out.available = true;
    return out;
}

struct StorageReading {
    double usedGiB = 0.0;
    double totalGiB = 0.0;
};

StorageReading readRootStorage() {
    struct statvfs stats {};
    if (statvfs("/", &stats) != 0 || stats.f_blocks == 0)
        return {};
    const long double blockSize = stats.f_frsize ? stats.f_frsize : stats.f_bsize;
    const long double total = static_cast<long double>(stats.f_blocks) * blockSize;
    const long double available = static_cast<long double>(stats.f_bavail) * blockSize;
    StorageReading out;
    out.totalGiB = static_cast<double>(total / BytesPerGiB);
    out.usedGiB = static_cast<double>((total - std::min(total, available)) / BytesPerGiB);
    return out;
}

qulonglong readUptimeSeconds() {
    QFile file(QStringLiteral("/proc/uptime"));
    if (!file.open(QIODevice::ReadOnly))
        return 0;
    bool ok = false;
    const double seconds = file.readLine().split(' ').value(0).toDouble(&ok);
    return ok && seconds > 0.0 ? static_cast<qulonglong>(seconds) : 0;
}

bool isCardName(const QString& name) {
    if (!name.startsWith(QStringLiteral("card")) || name.size() == 4)
        return false;
    for (qsizetype i = 4; i < name.size(); ++i) {
        if (!name[i].isDigit())
            return false;
    }
    return true;
}

bool runtimeSuspended(const QString& statusPath) {
    return !statusPath.isEmpty() && readSmallFile(statusPath).trimmed() == "suspended";
}

struct GpuCandidate {
    QString driver;
    QString name;
    QString utilizationPath;
    QString runtimeStatusPath;
    quint64 vram = 0;
    int kind = 0;
};

bool stronger(const GpuCandidate& a, const GpuCandidate& b) {
    if (a.kind != b.kind)
        return a.kind > b.kind;
    if (a.vram != b.vram)
        return a.vram > b.vram;
    return a.driver < b.driver;
}

QVector<GpuCandidate> discoverSysfsGpus() {
    QVector<GpuCandidate> found;
    QSet<QString> seenDevices;
    const QDir drm(QStringLiteral("/sys/class/drm"));
    const QFileInfoList entries = drm.entryInfoList(QStringList{QStringLiteral("card*")}, QDir::Dirs | QDir::NoDotAndDotDot,
                                                     QDir::Name);
    for (const QFileInfo& entry : entries) {
        if (!isCardName(entry.fileName()))
            continue;
        const QString devicePath = entry.absoluteFilePath() + QStringLiteral("/device");
        QFileInfo device(devicePath);
        if (!device.exists())
            continue;
        const QString identity = device.canonicalFilePath();
        if (identity.isEmpty() || seenDevices.contains(identity))
            continue;
        seenDevices.insert(identity);

        GpuCandidate candidate;
        candidate.driver = ueventField(devicePath, "DRIVER");
        if (candidate.driver.isEmpty())
            candidate.driver = QFileInfo(devicePath + QStringLiteral("/driver")).symLinkTarget().section('/', -1);
        candidate.vram = readUnsignedFile(devicePath + QStringLiteral("/mem_info_vram_total"));
        const quint64 visibleVram = readUnsignedFile(devicePath + QStringLiteral("/mem_info_vis_vram_total"));
        const QString removable = readTextFile(devicePath + QStringLiteral("/removable"));
        const bool discrete = candidate.driver == QStringLiteral("nvidia") || candidate.driver == QStringLiteral("nouveau")
            || (visibleVram > 0 && (visibleVram != candidate.vram || candidate.vram > 8ULL * 1024ULL * 1024ULL * 1024ULL))
            || (visibleVram == 0 && candidate.vram >= 2ULL * 1024ULL * 1024ULL * 1024ULL);
        candidate.kind = (removable == QStringLiteral("removable") || removable == QStringLiteral("1")) ? 2
                                                                                                           : (discrete ? 1 : 0);
        candidate.runtimeStatusPath = devicePath + QStringLiteral("/power/runtime_status");
        const QStringList utilizationNames{QStringLiteral("gpu_busy_percent"), QStringLiteral("gt_busy_percent")};
        for (const QString& name : utilizationNames) {
            const QString path = devicePath + '/' + name;
            if (QFileInfo::exists(path)) {
                candidate.utilizationPath = path;
                break;
            }
        }
        candidate.name = readTextFile(devicePath + QStringLiteral("/product_name"));
        if (candidate.name.isEmpty())
            candidate.name = readTextFile(devicePath + QStringLiteral("/marketing_name"));
        if (candidate.name.isEmpty()) {
            if (candidate.driver == QStringLiteral("amdgpu"))
                candidate.name = QStringLiteral("AMD GPU");
            else if (candidate.driver == QStringLiteral("i915") || candidate.driver == QStringLiteral("xe"))
                candidate.name = QStringLiteral("Intel GPU");
            else if (candidate.driver == QStringLiteral("nvidia") || candidate.driver == QStringLiteral("nouveau"))
                candidate.name = QStringLiteral("NVIDIA GPU");
            else
                candidate.name = candidate.driver;
        }
        found.append(std::move(candidate));
    }
    return found;
}

using NvmlReturn = int;
using NvmlDevice = void*;
constexpr NvmlReturn NvmlSuccess = 0;

struct NvmlUtilization {
    unsigned int gpu;
    unsigned int memory;
};

struct NvmlMemory {
    unsigned long long total;
    unsigned long long free;
    unsigned long long used;
};

class GpuSampler {
public:
    ~GpuSampler() { stopNvml(); }

    template<typename Cancelled>
    QString discover(Cancelled&& cancelled) {
        const QVector<GpuCandidate> candidates = discoverSysfsGpus();
        if (candidates.isEmpty() || cancelled())
            return {};

        GpuCandidate best = candidates.front();
        bool hasNvidia = false;
        bool nvidiaMayBeProbed = true;
        for (const GpuCandidate& candidate : candidates) {
            if (stronger(candidate, best))
                best = candidate;
            if (candidate.driver == QStringLiteral("nvidia")) {
                hasNvidia = true;
                m_nvidiaRuntimePaths.append(candidate.runtimeStatusPath);
                if (runtimeSuspended(candidate.runtimeStatusPath))
                    nvidiaMayBeProbed = false;
            }
        }

        NvmlChoice nvml;
        if (hasNvidia && nvidiaMayBeProbed && !cancelled())
            nvml = startNvml();
        if (nvml.valid) {
            GpuCandidate nvmlCandidate;
            nvmlCandidate.driver = QStringLiteral("nvidia");
            nvmlCandidate.name = nvml.name;
            nvmlCandidate.vram = nvml.memoryBytes;
            nvmlCandidate.kind = 1;
            if (stronger(nvmlCandidate, best) || best.driver == QStringLiteral("nvidia")) {
                m_backend = Backend::Nvml;
                m_nvmlDevice = nvml.device;
                m_name = nvml.name;
                return m_name;
            }
        }

        stopNvml();
        m_runtimeStatusPath = best.runtimeStatusPath;
        m_name = best.name;
        if (!best.utilizationPath.isEmpty()) {
            m_backend = Backend::Sysfs;
            m_utilizationPath = best.utilizationPath;
        }
        return m_name;
    }

    bool sample(double& percent) {
        if (m_backend == Backend::Sysfs) {
            if (runtimeSuspended(m_runtimeStatusPath))
                return false;
            bool ok = false;
            const double value = readSmallFile(m_utilizationPath).trimmed().toDouble(&ok);
            if (!ok || !std::isfinite(value))
                return false;
            percent = std::clamp(value, 0.0, 100.0);
            return true;
        }
        if (m_backend == Backend::Nvml) {
            for (const QString& path : std::as_const(m_nvidiaRuntimePaths)) {
                if (runtimeSuspended(path))
                    return false;
            }
            NvmlUtilization utilization{};
            if (!m_getUtilization || m_getUtilization(m_nvmlDevice, &utilization) != NvmlSuccess)
                return false;
            percent = std::min(100u, utilization.gpu);
            return true;
        }
        return false;
    }

private:
    enum class Backend { None, Sysfs, Nvml };
    using Init = NvmlReturn (*)();
    using Shutdown = NvmlReturn (*)();
    using GetCount = NvmlReturn (*)(unsigned int*);
    using GetHandle = NvmlReturn (*)(unsigned int, NvmlDevice*);
    using GetUtilization = NvmlReturn (*)(NvmlDevice, NvmlUtilization*);
    using GetName = NvmlReturn (*)(NvmlDevice, char*, unsigned int);
    using GetMemory = NvmlReturn (*)(NvmlDevice, NvmlMemory*);

    struct NvmlChoice {
        NvmlDevice device = nullptr;
        QString name;
        quint64 memoryBytes = 0;
        bool valid = false;
    };

    template<typename Function>
    Function resolve(const char* name) {
        return reinterpret_cast<Function>(m_nvml.resolve(name));
    }

    NvmlChoice startNvml() {
        m_nvml.setFileNameAndVersion(QStringLiteral("nvidia-ml"), 1);
        if (!m_nvml.load())
            return {};
        m_init = resolve<Init>("nvmlInit_v2");
        if (!m_init)
            m_init = resolve<Init>("nvmlInit");
        m_shutdown = resolve<Shutdown>("nvmlShutdown");
        m_getCount = resolve<GetCount>("nvmlDeviceGetCount_v2");
        if (!m_getCount)
            m_getCount = resolve<GetCount>("nvmlDeviceGetCount");
        m_getHandle = resolve<GetHandle>("nvmlDeviceGetHandleByIndex_v2");
        if (!m_getHandle)
            m_getHandle = resolve<GetHandle>("nvmlDeviceGetHandleByIndex");
        m_getUtilization = resolve<GetUtilization>("nvmlDeviceGetUtilizationRates");
        m_getName = resolve<GetName>("nvmlDeviceGetName");
        m_getMemory = resolve<GetMemory>("nvmlDeviceGetMemoryInfo");
        if (!m_init || !m_shutdown || !m_getCount || !m_getHandle || !m_getUtilization || m_init() != NvmlSuccess) {
            stopNvml();
            return {};
        }
        m_nvmlInitialized = true;

        unsigned int count = 0;
        if (m_getCount(&count) != NvmlSuccess)
            return {};
        NvmlChoice best;
        for (unsigned int index = 0; index < count; ++index) {
            NvmlDevice device = nullptr;
            if (m_getHandle(index, &device) != NvmlSuccess || !device)
                continue;
            NvmlMemory memory{};
            const quint64 total = m_getMemory && m_getMemory(device, &memory) == NvmlSuccess ? memory.total : 0;
            if (best.valid && total <= best.memoryBytes)
                continue;
            std::array<char, 128> name{};
            if (m_getName)
                m_getName(device, name.data(), name.size());
            best.device = device;
            best.memoryBytes = total;
            best.name = name[0] ? QString::fromUtf8(name.data()) : QStringLiteral("NVIDIA GPU");
            best.valid = true;
        }
        return best;
    }

    void stopNvml() {
        if (m_nvmlInitialized && m_shutdown)
            m_shutdown();
        m_nvmlInitialized = false;
        m_nvmlDevice = nullptr;
        m_init = nullptr;
        m_shutdown = nullptr;
        m_getCount = nullptr;
        m_getHandle = nullptr;
        m_getUtilization = nullptr;
        m_getName = nullptr;
        m_getMemory = nullptr;
        if (m_nvml.isLoaded())
            m_nvml.unload();
    }

    Backend m_backend = Backend::None;
    QString m_name;
    QString m_utilizationPath;
    QString m_runtimeStatusPath;
    QStringList m_nvidiaRuntimePaths;
    QLibrary m_nvml;
    NvmlDevice m_nvmlDevice = nullptr;
    Init m_init = nullptr;
    Shutdown m_shutdown = nullptr;
    GetCount m_getCount = nullptr;
    GetHandle m_getHandle = nullptr;
    GetUtilization m_getUtilization = nullptr;
    GetName m_getName = nullptr;
    GetMemory m_getMemory = nullptr;
    bool m_nvmlInitialized = false;
};

struct WorkerSample {
    qint64 monotonicMs = 0;
    double cpuPercent = 0.0;
    double memoryPercent = 0.0;
    double gpuPercent = 0.0;
    double memoryUsedGiB = 0.0;
    double memoryTotalGiB = 0.0;
    double storageUsedGiB = 0.0;
    double storageTotalGiB = 0.0;
    qulonglong uptimeSeconds = 0;
    bool cpuAvailable = false;
    bool memoryAvailable = false;
    bool gpuAvailable = false;
};

} // namespace

SystemMonitor::SystemMonitor(QObject* parent)
    : QObject(parent) {
    startWorker();
}

SystemMonitor::~SystemMonitor() {
    m_workerActive.store(false, std::memory_order_release);
    m_generation.fetch_add(1, std::memory_order_relaxed);
    stopWorker();
}

void SystemMonitor::setActive(bool active) {
    if (m_active == active)
        return;

    m_active = active;
    m_generation.fetch_add(1, std::memory_order_relaxed);
    m_workerActive.store(active, std::memory_order_release);
    clearValues();
    emit samplesChanged();
    emit activeChanged();
    m_workerWake.notify_all();
}

void SystemMonitor::clearValues() {
    m_cpuPercent = 0.0;
    m_memoryPercent = 0.0;
    m_gpuPercent = 0.0;
    m_cpuAvailable = false;
    m_memoryAvailable = false;
    m_gpuAvailable = false;
    m_cpuName.clear();
    m_gpuName.clear();
    m_userName.clear();
    m_hostName.clear();
    m_uptimeSeconds = 0;
    m_memoryUsedGiB = 0.0;
    m_memoryTotalGiB = 0.0;
    m_storageUsedGiB = 0.0;
    m_storageTotalGiB = 0.0;
    m_historyStart = 0;
    m_historyCount = 0;
}

void SystemMonitor::startWorker() {
    m_worker = std::jthread([this](std::stop_token stop) {
        while (!stop.stop_requested()) {
            std::unique_lock activationLock(m_workerMutex);
            m_workerWake.wait(activationLock, stop, [this] {
                return m_workerActive.load(std::memory_order_acquire);
            });
            if (stop.stop_requested())
                break;
            const quint64 generation = m_generation.load(std::memory_order_relaxed);
            activationLock.unlock();

            const auto cancelled = [this, stop, generation] {
                return stop.stop_requested() || !m_workerActive.load(std::memory_order_acquire)
                    || generation != m_generation.load(std::memory_order_relaxed);
            };
            GpuSampler gpu;
            IdentityResult identity;
            identity.cpuName = cpuModelName();
            if (cancelled())
                continue;
            identity.gpuName = gpu.discover(cancelled);
            if (cancelled())
                continue;
            identity.userName = currentUserName();
            identity.hostName = currentHostName();
            if (cancelled())
                continue;
            QMetaObject::invokeMethod(this, [this, generation, identity = std::move(identity)]() mutable {
                applyIdentity(generation, std::move(identity));
            }, Qt::QueuedConnection);

            CpuTotals previousCpu;
            auto nextSample = Clock::now();
            while (!stop.stop_requested() && m_workerActive.load(std::memory_order_acquire)
                   && generation == m_generation.load(std::memory_order_relaxed)) {
                WorkerSample sample;
                sample.monotonicMs = monotonicMilliseconds();

                const CpuTotals cpu = readCpuTotals();
                if (cpu.valid && previousCpu.valid && cpu.total > previousCpu.total) {
                    const quint64 totalDelta = cpu.total - previousCpu.total;
                    const quint64 idleDelta = cpu.idle >= previousCpu.idle ? cpu.idle - previousCpu.idle : 0;
                    sample.cpuPercent = 100.0 * static_cast<double>(totalDelta - std::min(totalDelta, idleDelta))
                        / static_cast<double>(totalDelta);
                    sample.cpuPercent = std::clamp(sample.cpuPercent, 0.0, 100.0);
                    sample.cpuAvailable = true;
                }
                previousCpu = cpu;

                const MemoryReading memory = readMemory();
                sample.memoryPercent = memory.percent;
                sample.memoryUsedGiB = memory.usedGiB;
                sample.memoryTotalGiB = memory.totalGiB;
                sample.memoryAvailable = memory.available;

                sample.gpuAvailable = gpu.sample(sample.gpuPercent);
                sample.uptimeSeconds = readUptimeSeconds();
                const StorageReading storage = readRootStorage();
                sample.storageUsedGiB = storage.usedGiB;
                sample.storageTotalGiB = storage.totalGiB;

                SampleResult result;
                result.monotonicMs = sample.monotonicMs;
                result.cpuPercent = sample.cpuPercent;
                result.memoryPercent = sample.memoryPercent;
                result.gpuPercent = sample.gpuPercent;
                result.memoryUsedGiB = sample.memoryUsedGiB;
                result.memoryTotalGiB = sample.memoryTotalGiB;
                result.storageUsedGiB = sample.storageUsedGiB;
                result.storageTotalGiB = sample.storageTotalGiB;
                result.uptimeSeconds = sample.uptimeSeconds;
                result.cpuAvailable = sample.cpuAvailable;
                result.memoryAvailable = sample.memoryAvailable;
                result.gpuAvailable = sample.gpuAvailable;
                if (m_workerActive.load(std::memory_order_acquire)
                    && generation == m_generation.load(std::memory_order_relaxed)) {
                    QMetaObject::invokeMethod(
                        this, [this, generation, result] { applySample(generation, result); }, Qt::QueuedConnection);
                }

                nextSample += std::chrono::seconds(1);
                const auto finished = Clock::now();
                if (nextSample <= finished)
                    nextSample = finished + std::chrono::seconds(1);
                std::unique_lock sampleLock(m_workerMutex);
                m_workerWake.wait_until(sampleLock, stop, nextSample, [this, generation] {
                    return !m_workerActive.load(std::memory_order_acquire)
                        || generation != m_generation.load(std::memory_order_relaxed);
                });
            }
        }
    });
}

void SystemMonitor::stopWorker() {
    if (!m_worker.joinable())
        return;
    m_worker.request_stop();
    m_workerWake.notify_all();
    m_worker.join();
    m_worker = std::jthread{};
}

void SystemMonitor::applyIdentity(quint64 generation, IdentityResult result) {
    if (!m_active || generation != m_generation.load(std::memory_order_relaxed))
        return;
    m_cpuName = std::move(result.cpuName);
    m_gpuName = std::move(result.gpuName);
    m_userName = std::move(result.userName);
    m_hostName = std::move(result.hostName);
    emit samplesChanged();
}

void SystemMonitor::applySample(quint64 generation, const SampleResult& result) {
    if (!m_active || generation != m_generation.load(std::memory_order_relaxed))
        return;

    m_cpuPercent = result.cpuPercent;
    m_memoryPercent = result.memoryPercent;
    m_gpuPercent = result.gpuPercent;
    m_cpuAvailable = result.cpuAvailable;
    m_memoryAvailable = result.memoryAvailable;
    m_gpuAvailable = result.gpuAvailable;
    m_uptimeSeconds = result.uptimeSeconds;
    m_memoryUsedGiB = result.memoryUsedGiB;
    m_memoryTotalGiB = result.memoryTotalGiB;
    m_storageUsedGiB = result.storageUsedGiB;
    m_storageTotalGiB = result.storageTotalGiB;

    const int index = (m_historyStart + m_historyCount) % HistoryCapacity;
    HistorySample history;
    history.monotonicMs = result.monotonicMs;
    history.cpu = result.cpuAvailable ? static_cast<float>(result.cpuPercent) : std::numeric_limits<float>::quiet_NaN();
    history.memory = result.memoryAvailable ? static_cast<float>(result.memoryPercent)
                                            : std::numeric_limits<float>::quiet_NaN();
    history.gpu = result.gpuAvailable ? static_cast<float>(result.gpuPercent) : std::numeric_limits<float>::quiet_NaN();
    if (m_historyCount < HistoryCapacity) {
        m_history[index] = history;
        ++m_historyCount;
    } else {
        m_history[m_historyStart] = history;
        m_historyStart = (m_historyStart + 1) % HistoryCapacity;
    }
    emit samplesChanged();
}

const SystemMonitor::HistorySample& SystemMonitor::historyAtOldest(int index) const {
    Q_ASSERT(index >= 0 && index < m_historyCount);
    return m_history[(m_historyStart + index) % HistoryCapacity];
}
