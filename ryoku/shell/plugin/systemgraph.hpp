#pragma once

#include "systemmonitor.hpp"

#include <QColor>
#include <QPointer>
#include <QQuickItem>
#include <QTimer>
#include <qqmlregistration.h>

#include <array>
#include <atomic>

class SystemGraph : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(SystemMonitor* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool animated READ animated WRITE setAnimated NOTIFY animatedChanged)
    Q_PROPERTY(QColor cpuColor READ cpuColor WRITE setCpuColor NOTIFY cpuColorChanged)
    Q_PROPERTY(QColor memoryColor READ memoryColor WRITE setMemoryColor NOTIFY memoryColorChanged)
    Q_PROPERTY(QColor gpuColor READ gpuColor WRITE setGpuColor NOTIFY gpuColorChanged)
    Q_PROPERTY(QColor gridColor READ gridColor WRITE setGridColor NOTIFY gridColorChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)
    Q_PROPERTY(int sampleCount READ sampleCount NOTIFY sampleCountChanged)
    Q_PROPERTY(int windowSeconds READ windowSeconds NOTIFY sampleCountChanged)
    Q_PROPERTY(qulonglong frameCount READ frameCount)

public:
    explicit SystemGraph(QQuickItem* parent = nullptr);
    ~SystemGraph() override;

    SystemMonitor* source() const { return m_source; }
    void setSource(SystemMonitor* source);
    bool active() const { return m_active; }
    void setActive(bool active);
    bool animated() const { return m_animated; }
    void setAnimated(bool animated);
    QColor cpuColor() const { return m_cpuColor; }
    void setCpuColor(const QColor& color);
    QColor memoryColor() const { return m_memoryColor; }
    void setMemoryColor(const QColor& color);
    QColor gpuColor() const { return m_gpuColor; }
    void setGpuColor(const QColor& color);
    QColor gridColor() const { return m_gridColor; }
    void setGridColor(const QColor& color);
    qreal lineWidth() const { return m_lineWidth; }
    void setLineWidth(qreal width);
    int sampleCount() const { return m_sampleCount; }
    int windowSeconds() const;
    qulonglong frameCount() const { return m_frameCount.load(std::memory_order_relaxed); }

signals:
    void sourceChanged();
    void activeChanged();
    void animatedChanged();
    void cpuColorChanged();
    void memoryColorChanged();
    void gpuColorChanged();
    void gridColorChanged();
    void lineWidthChanged();
    void sampleCountChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) override;
    void itemChange(ItemChange change, const ItemChangeData& data) override;
    bool eventFilter(QObject* watched, QEvent* event) override;

private:
    static constexpr int SampleCapacity = SystemMonitor::HistoryCapacity;

    struct Sample {
        qint64 monotonicMs = 0;
        float cpu = 0.0f;
        float memory = 0.0f;
        float gpu = 0.0f;
    };

    void syncFromSource();
    void handleWindowChanged(QQuickWindow* window);
    void updateAnimationState();
    void requestAnimationFrame();
    void markVisualDirty();

    QPointer<SystemMonitor> m_source;
    QMetaObject::Connection m_samplesConnection;
    QMetaObject::Connection m_sourceDestroyedConnection;
    QPointer<QQuickWindow> m_observedWindow;
    QTimer m_frameTimer;
    std::array<Sample, SampleCapacity> m_samples{};
    int m_sampleCount = 0;
    bool m_active = false;
    bool m_animated = true;
    QColor m_cpuColor = Qt::white;
    QColor m_memoryColor = Qt::white;
    QColor m_gpuColor = Qt::white;
    QColor m_gridColor = Qt::transparent;
    qreal m_lineWidth = 2.0;
    std::atomic<qulonglong> m_frameCount{0};
};
