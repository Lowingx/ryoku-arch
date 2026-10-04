#include "systemgraph.hpp"

#include <QEvent>
#include <QQuickWindow>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGNode>
#include <QSGVertexColorMaterial>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>

namespace {

using Vertex = QSGGeometry::ColoredPoint2D;
constexpr int Subdivisions = 4;
constexpr int MaxIntervals = SystemMonitor::HistoryCapacity - 1;
constexpr int MaxFillVertices = MaxIntervals * Subdivisions * 6;
constexpr int MaxLineVertices = MaxIntervals * Subdivisions * 18;
constexpr int PointSegments = 12;
constexpr int PointVertices = PointSegments * 3;
constexpr int GridLines = 7;
constexpr int GridVertices = GridLines * 6;
constexpr qint64 ValueBlendMilliseconds = 420;

qint64 monotonicMilliseconds() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(
               std::chrono::steady_clock::now().time_since_epoch())
        .count();
}

class ColorNode final : public QSGGeometryNode {
public:
    explicit ColorNode(int vertexCapacity) {
        buffer = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), vertexCapacity);
        buffer->setDrawingMode(QSGGeometry::DrawTriangles);
        buffer->setVertexDataPattern(QSGGeometry::DynamicPattern);
        auto* vertexMaterial = new QSGVertexColorMaterial;
        vertexMaterial->setFlag(QSGMaterial::Blending);
        setGeometry(buffer);
        setMaterial(vertexMaterial);
        setFlag(QSGNode::OwnsGeometry);
        setFlag(QSGNode::OwnsMaterial);
        clear();
    }

    void clear() {
        Vertex* vertices = buffer->vertexDataAsColoredPoint2D();
        for (int i = 0; i < buffer->vertexCount(); ++i)
            vertices[i].set(0.0f, 0.0f, 0, 0, 0, 0);
        markDirty(QSGNode::DirtyGeometry);
    }

    QSGGeometry* buffer = nullptr;
    int usedVertices = 0;
};

struct GraphNode final : QSGNode {
    GraphNode() {
        grid = new ColorNode(GridVertices);
        appendChildNode(grid);
        for (int i = 0; i < 3; ++i) {
            fills[i] = new ColorNode(MaxFillVertices);
            appendChildNode(fills[i]);
        }
        for (int i = 0; i < 3; ++i) {
            lines[i] = new ColorNode(MaxLineVertices);
            appendChildNode(lines[i]);
        }
        for (int i = 0; i < 3; ++i) {
            points[i] = new ColorNode(PointVertices);
            appendChildNode(points[i]);
        }
    }

    ColorNode* grid = nullptr;
    std::array<ColorNode*, 3> fills{};
    std::array<ColorNode*, 3> lines{};
    std::array<ColorNode*, 3> points{};
    float gridWidth = -1.0f;
    float gridHeight = -1.0f;
    QColor gridColor;
};

struct Point {
    float x = 0.0f;
    float y = 0.0f;
};

struct Rgba {
    unsigned char r = 0;
    unsigned char g = 0;
    unsigned char b = 0;
    unsigned char a = 0;
};

Rgba premultiplied(const QColor& color, float opacity) {
    const float alpha = std::clamp(color.alphaF() * opacity, 0.0f, 1.0f);
    return {
        static_cast<unsigned char>(std::lround(color.redF() * alpha * 255.0f)),
        static_cast<unsigned char>(std::lround(color.greenF() * alpha * 255.0f)),
        static_cast<unsigned char>(std::lround(color.blueF() * alpha * 255.0f)),
        static_cast<unsigned char>(std::lround(alpha * 255.0f)),
    };
}

void setVertex(Vertex& vertex, const Point& point, const Rgba& color) {
    vertex.set(point.x, point.y, color.r, color.g, color.b, color.a);
}

void appendQuad(Vertex* vertices, int& offset, const Point& a, const Point& b, const Point& c, const Point& d,
                const Rgba& ca, const Rgba& cb, const Rgba& cc, const Rgba& cd) {
    setVertex(vertices[offset++], a, ca);
    setVertex(vertices[offset++], b, cb);
    setVertex(vertices[offset++], c, cc);
    setVertex(vertices[offset++], a, ca);
    setVertex(vertices[offset++], c, cc);
    setVertex(vertices[offset++], d, cd);
}

void clearRemainder(ColorNode* node, int offset) {
    Vertex* vertices = node->buffer->vertexDataAsColoredPoint2D();
    for (int i = offset; i < node->usedVertices; ++i)
        vertices[i].set(0.0f, 0.0f, 0, 0, 0, 0);
    node->usedVertices = offset;
    node->markDirty(QSGNode::DirtyGeometry);
}

void appendAntialiasedLine(Vertex* vertices, int& offset, const Point& from, const Point& to, float width,
                           const Rgba& transparent, const Rgba& solid) {
    const float dx = to.x - from.x;
    const float dy = to.y - from.y;
    const float length = std::hypot(dx, dy);
    if (length < 0.001f)
        return;
    const float nx = -dy / length;
    const float ny = dx / length;
    const float inner = std::max(0.5f, width * 0.5f);
    const float outer = inner + 1.25f;

    const Point fromOuterLow{from.x - nx * outer, from.y - ny * outer};
    const Point fromInnerLow{from.x - nx * inner, from.y - ny * inner};
    const Point fromInnerHigh{from.x + nx * inner, from.y + ny * inner};
    const Point fromOuterHigh{from.x + nx * outer, from.y + ny * outer};
    const Point toOuterLow{to.x - nx * outer, to.y - ny * outer};
    const Point toInnerLow{to.x - nx * inner, to.y - ny * inner};
    const Point toInnerHigh{to.x + nx * inner, to.y + ny * inner};
    const Point toOuterHigh{to.x + nx * outer, to.y + ny * outer};

    appendQuad(vertices, offset, fromOuterLow, toOuterLow, toInnerLow, fromInnerLow,
               transparent, transparent, solid, solid);
    appendQuad(vertices, offset, fromInnerLow, toInnerLow, toInnerHigh, fromInnerHigh,
               solid, solid, solid, solid);
    appendQuad(vertices, offset, fromInnerHigh, toInnerHigh, toOuterHigh, fromOuterHigh,
               solid, solid, transparent, transparent);
}

void appendFill(Vertex* vertices, int& offset, const Point& from, const Point& to, float baseline,
                const Rgba& top, const Rgba& bottom) {
    const Point fromBase{from.x, baseline};
    const Point toBase{to.x, baseline};
    appendQuad(vertices, offset, from, to, toBase, fromBase, top, top, bottom, bottom);
}

float catmullRom(float p0, float p1, float p2, float p3, float t) {
    const float t2 = t * t;
    const float t3 = t2 * t;
    return 0.5f * ((2.0f * p1) + (-p0 + p2) * t + (2.0f * p0 - 5.0f * p1 + 4.0f * p2 - p3) * t2
                   + (-p0 + 3.0f * p1 - 3.0f * p2 + p3) * t3);
}

float smoothStep(float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

void buildGrid(ColorNode* node, float width, float height, const QColor& color) {
    Vertex* vertices = node->buffer->vertexDataAsColoredPoint2D();
    int offset = 0;
    const Rgba grid = premultiplied(color, 0.45f);
    const float thickness = 0.65f;
    const std::array<float, 3> vertical{0.25f, 0.5f, 0.75f};
    const std::array<float, 4> horizontal{0.2f, 0.4f, 0.6f, 0.8f};
    for (float fraction : vertical) {
        const float x = width * fraction;
        appendQuad(vertices, offset, {x - thickness, 0.0f}, {x + thickness, 0.0f},
                   {x + thickness, height}, {x - thickness, height}, grid, grid, grid, grid);
    }
    for (float fraction : horizontal) {
        const float y = height * fraction;
        appendQuad(vertices, offset, {0.0f, y - thickness}, {width, y - thickness},
                   {width, y + thickness}, {0.0f, y + thickness}, grid, grid, grid, grid);
    }
    clearRemainder(node, offset);
}

void buildPoint(ColorNode* node, const Point& center, float radius, const QColor& color, bool visible) {
    Vertex* vertices = node->buffer->vertexDataAsColoredPoint2D();
    int offset = 0;
    if (visible) {
        const Rgba centerColor = premultiplied(color, 1.0f);
        const Rgba edgeColor = premultiplied(color, 0.0f);
        constexpr float Tau = 6.2831853071795864769f;
        for (int segment = 0; segment < PointSegments; ++segment) {
            const float a = Tau * static_cast<float>(segment) / static_cast<float>(PointSegments);
            const float b = Tau * static_cast<float>(segment + 1) / static_cast<float>(PointSegments);
            setVertex(vertices[offset++], center, centerColor);
            setVertex(vertices[offset++], {center.x + std::cos(a) * radius, center.y + std::sin(a) * radius}, edgeColor);
            setVertex(vertices[offset++], {center.x + std::cos(b) * radius, center.y + std::sin(b) * radius}, edgeColor);
        }
    }
    clearRemainder(node, offset);
}

} // namespace

SystemGraph::SystemGraph(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
    m_frameTimer.setTimerType(Qt::PreciseTimer);
    m_frameTimer.setInterval(16);
    connect(&m_frameTimer, &QTimer::timeout, this, &SystemGraph::requestAnimationFrame);
    connect(this, &QQuickItem::windowChanged, this, &SystemGraph::handleWindowChanged);
    if (window())
        handleWindowChanged(window());
}

SystemGraph::~SystemGraph() {
    m_frameTimer.stop();
    if (m_observedWindow)
        m_observedWindow->removeEventFilter(this);
}

void SystemGraph::setSource(SystemMonitor* source) {
    if (m_source == source)
        return;
    disconnect(m_samplesConnection);
    disconnect(m_sourceDestroyedConnection);
    m_source = source;
    if (source) {
        m_samplesConnection = connect(source, &SystemMonitor::samplesChanged, this, &SystemGraph::syncFromSource);
        m_sourceDestroyedConnection = connect(source, &QObject::destroyed, this, [this] {
            m_source = nullptr;
            m_sampleCount = 0;
            emit sourceChanged();
            emit sampleCountChanged();
            updateAnimationState();
            markVisualDirty();
        });
    }
    syncFromSource();
    emit sourceChanged();
}

void SystemGraph::setActive(bool active) {
    if (m_active == active)
        return;
    m_active = active;
    emit activeChanged();
    updateAnimationState();
    update();
}

void SystemGraph::setAnimated(bool animated) {
    if (m_animated == animated)
        return;
    m_animated = animated;
    emit animatedChanged();
    updateAnimationState();
    markVisualDirty();
}

void SystemGraph::setCpuColor(const QColor& color) {
    if (m_cpuColor == color)
        return;
    m_cpuColor = color;
    emit cpuColorChanged();
    markVisualDirty();
}

void SystemGraph::setMemoryColor(const QColor& color) {
    if (m_memoryColor == color)
        return;
    m_memoryColor = color;
    emit memoryColorChanged();
    markVisualDirty();
}

void SystemGraph::setGpuColor(const QColor& color) {
    if (m_gpuColor == color)
        return;
    m_gpuColor = color;
    emit gpuColorChanged();
    markVisualDirty();
}

void SystemGraph::setGridColor(const QColor& color) {
    if (m_gridColor == color)
        return;
    m_gridColor = color;
    emit gridColorChanged();
    markVisualDirty();
}

void SystemGraph::setLineWidth(qreal width) {
    width = std::clamp(width, 0.5, 12.0);
    if (qFuzzyCompare(m_lineWidth, width))
        return;
    m_lineWidth = width;
    emit lineWidthChanged();
    markVisualDirty();
}

int SystemGraph::windowSeconds() const {
    if (m_sampleCount < 2)
        return 10;
    const qint64 observed = std::max<qint64>(
        1000, m_samples[m_sampleCount - 1].monotonicMs - m_samples[0].monotonicMs + 1000);
    return std::clamp(static_cast<int>((observed + 999) / 1000), 10, 60);
}

void SystemGraph::syncFromSource() {
    const int previousCount = m_sampleCount;
    m_sampleCount = m_source ? m_source->m_historyCount : 0;
    for (int i = 0; i < m_sampleCount; ++i) {
        const SystemMonitor::HistorySample& sample = m_source->historyAtOldest(i);
        m_samples[i] = {sample.monotonicMs, sample.cpu, sample.memory, sample.gpu};
    }
    if (previousCount != m_sampleCount)
        emit sampleCountChanged();
    updateAnimationState();
    markVisualDirty();
}

void SystemGraph::handleWindowChanged(QQuickWindow* window) {
    if (m_observedWindow)
        m_observedWindow->removeEventFilter(this);
    m_observedWindow = window;
    if (window)
        window->installEventFilter(this);
    updateAnimationState();
    markVisualDirty();
}

void SystemGraph::updateAnimationState() {
    const bool shouldAnimate = m_active && m_animated && m_sampleCount > 0 && isVisible() && m_observedWindow
        && m_observedWindow->isVisible() && m_observedWindow->isExposed();
    if (shouldAnimate) {
        if (!m_frameTimer.isActive())
            m_frameTimer.start();
    } else {
        m_frameTimer.stop();
    }
}

void SystemGraph::requestAnimationFrame() {
    if (!m_active || !m_animated || m_sampleCount == 0 || !isVisible() || !m_observedWindow
        || !m_observedWindow->isVisible() || !m_observedWindow->isExposed()) {
        m_frameTimer.stop();
        return;
    }
    update();
}

void SystemGraph::markVisualDirty() {
    if (m_active && isVisible())
        update();
}

void SystemGraph::itemChange(ItemChange change, const ItemChangeData& data) {
    QQuickItem::itemChange(change, data);
    if (change == ItemVisibleHasChanged) {
        updateAnimationState();
        if (data.boolValue)
            markVisualDirty();
    }
}

bool SystemGraph::eventFilter(QObject* watched, QEvent* event) {
    if (watched == m_observedWindow
        && (event->type() == QEvent::Expose || event->type() == QEvent::Show || event->type() == QEvent::Hide
            || event->type() == QEvent::PlatformSurface)) {
        updateAnimationState();
        if (m_active && m_observedWindow && m_observedWindow->isExposed())
            update();
    }
    return QQuickItem::eventFilter(watched, event);
}

QSGNode* SystemGraph::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) {
    if (!m_active || !isVisible() || !window() || !window()->isExposed() || width() <= 0.0 || height() <= 0.0) {
        delete oldNode;
        return nullptr;
    }

    auto* root = static_cast<GraphNode*>(oldNode);
    if (!root)
        root = new GraphNode;
    m_frameCount.fetch_add(1, std::memory_order_relaxed);

    const float graphWidth = static_cast<float>(width());
    const float graphHeight = static_cast<float>(height());
    if (root->gridWidth != graphWidth || root->gridHeight != graphHeight || root->gridColor != m_gridColor) {
        buildGrid(root->grid, graphWidth, graphHeight, m_gridColor);
        root->gridWidth = graphWidth;
        root->gridHeight = graphHeight;
        root->gridColor = m_gridColor;
    }

    const float plotWindowMilliseconds = static_cast<float>(windowSeconds() * 1000);
    const qint64 now = monotonicMilliseconds();
    for (int trace = 0; trace < 3; ++trace) {
        const QColor& color = trace == 0 ? m_cpuColor : (trace == 1 ? m_memoryColor : m_gpuColor);
        const Rgba lineTransparent = premultiplied(color, 0.0f);
        const Rgba lineSolid = premultiplied(color, 0.96f);
        const Rgba fillTop = premultiplied(color, 0.15f);
        const Rgba fillBottom = premultiplied(color, 0.015f);
        const float detailRadius = std::max(3.0f, static_cast<float>(m_lineWidth) * 2.1f);
        const float plotWidth = std::max(0.0f, graphWidth - detailRadius * 2.0f);
        const float plotHeight = std::max(0.0f, graphHeight - detailRadius * 2.0f);
        ColorNode* fillNode = root->fills[trace];
        ColorNode* lineNode = root->lines[trace];
        Vertex* fillVertices = fillNode->buffer->vertexDataAsColoredPoint2D();
        Vertex* lineVertices = lineNode->buffer->vertexDataAsColoredPoint2D();
        int fillOffset = 0;
        int lineOffset = 0;

        const auto rawValue = [this, trace](int index) {
            if (trace == 0)
                return m_samples[index].cpu;
            if (trace == 1)
                return m_samples[index].memory;
            return m_samples[index].gpu;
        };
        const auto valueAt = [&](int index) {
            float value = rawValue(index);
            if (m_animated && index == m_sampleCount - 1 && index > 0 && std::isfinite(value)) {
                const float previous = rawValue(index - 1);
                if (std::isfinite(previous)) {
                    const float progress = static_cast<float>(now - m_samples[index].monotonicMs)
                        / static_cast<float>(ValueBlendMilliseconds);
                    value = previous + (value - previous) * smoothStep(progress);
                }
            }
            return value;
        };
        const auto pointFor = [&](int index, float value) {
            const qint64 age = std::max<qint64>(0, now - m_samples[index].monotonicMs);
            const float x = detailRadius
                + plotWidth * (1.0f - static_cast<float>(age) / plotWindowMilliseconds);
            const float y = detailRadius
                + plotHeight * (1.0f - std::clamp(value, 0.0f, 100.0f) / 100.0f);
            return Point{x, y};
        };

        for (int i = 0; i + 1 < m_sampleCount; ++i) {
            const float p1Value = valueAt(i);
            const float p2Value = valueAt(i + 1);
            if (!std::isfinite(p1Value) || !std::isfinite(p2Value))
                continue;
            const float previousValue = i > 0 ? valueAt(i - 1) : p1Value;
            const float followingValue = i + 2 < m_sampleCount ? valueAt(i + 2) : p2Value;
            const float p0Value = std::isfinite(previousValue) ? previousValue : p1Value;
            const float p3Value = std::isfinite(followingValue) ? followingValue : p2Value;
            const Point p1 = pointFor(i, p1Value);
            const Point p2 = pointFor(i + 1, p2Value);
            if (p2.x < 0.0f || p1.x > graphWidth)
                continue;

            Point previous{std::clamp(p1.x, 0.0f, graphWidth), p1.y};
            for (int subdivision = 1; subdivision <= Subdivisions; ++subdivision) {
                const float t = static_cast<float>(subdivision) / static_cast<float>(Subdivisions);
                Point current;
                current.x = std::clamp(p1.x + (p2.x - p1.x) * t, 0.0f, graphWidth);
                const float value = std::clamp(catmullRom(p0Value, p1Value, p2Value, p3Value, t), 0.0f, 100.0f);
                current.y = graphHeight * (1.0f - value / 100.0f);
                appendFill(fillVertices, fillOffset, previous, current, graphHeight, fillTop, fillBottom);
                appendAntialiasedLine(lineVertices, lineOffset, previous, current, static_cast<float>(m_lineWidth),
                                      lineTransparent, lineSolid);
                previous = current;
            }
        }
        clearRemainder(fillNode, fillOffset);
        clearRemainder(lineNode, lineOffset);

        Point newest;
        bool newestVisible = false;
        if (m_sampleCount > 0) {
            const float newestValue = valueAt(m_sampleCount - 1);
            if (std::isfinite(newestValue)) {
                newest = pointFor(m_sampleCount - 1, newestValue);
                newestVisible = newest.x >= 0.0f && newest.x <= graphWidth;
            }
        }
        buildPoint(root->points[trace], newest, detailRadius, color, newestVisible);
    }

    return root;
}
