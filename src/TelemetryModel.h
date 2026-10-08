#ifndef TELEMETRYMODEL_H
#define TELEMETRYMODEL_H

#include <QAbstractListModel>
#include <QAbstractItemModel>
#include <QDateTime>
#include <QVector>
#include <QString>
#include <qqmlintegration.h>

struct TelemetryRecord {
    int id;
    QString timestamp;
    double speed;        // KM/H
    double acceleration; // m/s^2
    QString status;
    QString statusColor;
};

class TelemetryModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum TelemetryRoles {
        IdRole = Qt::UserRole + 1,
        TimestampRole,
        SpeedRole,
        AccelerationRole,
        StatusRole,
        StatusColorRole
    };

    explicit TelemetryModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addRecord(double speed, double acceleration, bool isAccelerating);
    Q_INVOKABLE void clearLogs();

    const QVector<TelemetryRecord>& records() const { return m_records; }

signals:
    void countChanged();

private:
    QVector<TelemetryRecord> m_records;
    int m_nextId;
};

#endif // TELEMETRYMODEL_H
