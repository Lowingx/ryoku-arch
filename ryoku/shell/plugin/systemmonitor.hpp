#pragma once

#include <QObject>
#include <QString>
#include <qqmlregistration.h>

#include <array>
#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <limits>
#include <mutex>
#include <thread>

class SystemGraph;

class SystemMonitor : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(qreal cpuPercent READ cpuPercent NOTIFY samplesChanged)
    Q_PROPERTY(qreal memoryPercent READ memoryPercent NOTIFY samplesChanged)
    Q_PROPERTY(qreal gpuPercent READ gpuPercent NOTIFY samplesChanged)
    Q_PROPERTY(bool cpuAvailable READ cpuAvailable NOTIFY samplesChanged)
    Q_PROPERTY(bool memoryAvailable READ memoryAvailable NOTIFY samplesChanged)
    Q_PROPERTY(bool gpuAvailable READ gpuAvailable NOTIFY samplesChanged)
    Q_PROPERTY(QString cpuName READ cpuName NOTIFY samplesChanged)
    Q_PROPERTY(QString gpuName READ gpuName NOTIFY samplesChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY samplesChanged)
    Q_PROPERTY(QString hostName READ hostName NOTIFY samplesChanged)
    Q_PROPERTY(qulonglong uptimeSeconds READ uptimeSeconds NOTIFY samplesChanged)
    Q_PROPERTY(qreal memoryUsedGiB READ memoryUsedGiB NOTIFY samplesChanged)
    Q_PROPERTY(qreal memoryTotalGiB READ memoryTotalGiB NOTIFY samplesChanged)
    Q_PROPERTY(qreal storageUsedGiB READ storageUsedGiB NOTIFY samplesChanged)
    Q_PROPERTY(qreal storageTotalGiB READ storageTotalGiB NOTIFY samplesChanged)
    Q_PROPERTY(int sampleCount READ sampleCount NOTIFY samplesChanged)

public:
    explicit SystemMonitor(QObject* parent = nullptr);
    ~SystemMonitor() override;
    static constexpr int HistoryCapacity = 60;


    bool active() const { return m_active; }
    void setActive(bool active);

    qreal cpuPercent() const { return m_cpuPercent; }
    qreal memoryPercent() const { return m_memoryPercent; }
    qreal gpuPercent() const { return m_gpuPercent; }
    bool cpuAvailable() const { return m_cpuAvailable; }
    bool memoryAvailable() const { return m_memoryAvailable; }
    bool gpuAvailable() const { return m_gpuAvailable; }
    const QString& cpuName() const { return m_cpuName; }
    const QString& gpuName() const { return m_gpuName; }
    const QString& userName() const { return m_userName; }
    const QString& hostName() const { return m_hostName; }
    qulonglong uptimeSeconds() const { return m_uptimeSeconds; }
    qreal memoryUsedGiB() const { return m_memoryUsedGiB; }
    qreal memoryTotalGiB() const { return m_memoryTotalGiB; }
    qreal storageUsedGiB() const { return m_storageUsedGiB; }
    qreal storageTotalGiB() const { return m_storageTotalGiB; }
    int sampleCount() const { return m_historyCount; }

signals:
    void activeChanged();
    void samplesChanged();

private:
    friend class SystemGraph;


    struct HistorySample {
        qint64 monotonicMs = 0;
        float cpu = std::numeric_limits<float>::quiet_NaN();
        float memory = std::numeric_limits<float>::quiet_NaN();
        float gpu = std::numeric_limits<float>::quiet_NaN();
    };

    struct IdentityResult {
        QString cpuName;
        QString gpuName;
        QString userName;
        QString hostName;
    };

    struct SampleResult {
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

    const HistorySample& historyAtOldest(int index) const;
    void startWorker();
    void stopWorker();
    void applyIdentity(quint64 generation, IdentityResult result);
    void applySample(quint64 generation, const SampleResult& result);
    void clearValues();

    bool m_active = false;
    std::atomic<quint64> m_generation{0};
    std::atomic_bool m_workerActive{false};
    std::mutex m_workerMutex;
    std::condition_variable_any m_workerWake;
    std::jthread m_worker;

    qreal m_cpuPercent = 0.0;
    qreal m_memoryPercent = 0.0;
    qreal m_gpuPercent = 0.0;
    bool m_cpuAvailable = false;
    bool m_memoryAvailable = false;
    bool m_gpuAvailable = false;
    QString m_cpuName;
    QString m_gpuName;
    QString m_userName;
    QString m_hostName;
    qulonglong m_uptimeSeconds = 0;
    qreal m_memoryUsedGiB = 0.0;
    qreal m_memoryTotalGiB = 0.0;
    qreal m_storageUsedGiB = 0.0;
    qreal m_storageTotalGiB = 0.0;

    std::array<HistorySample, HistoryCapacity> m_history{};
    int m_historyStart = 0;
    int m_historyCount = 0;
};
