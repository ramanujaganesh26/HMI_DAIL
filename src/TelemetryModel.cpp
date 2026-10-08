#include "TelemetryModel.h"

TelemetryModel::TelemetryModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_nextId(1)
{
}

int TelemetryModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_records.count();
}

QVariant TelemetryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_records.count())
        return QVariant();

    const auto &record = m_records.at(index.row());

    switch (role) {
    case IdRole:
        return record.id;
    case TimestampRole:
        return record.timestamp;
    case SpeedRole:
        return record.speed;
    case AccelerationRole:
        return record.acceleration;
    case StatusRole:
        return record.status;
    case StatusColorRole:
        return record.statusColor;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> TelemetryModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "logId";
    roles[TimestampRole] = "time";
    roles[SpeedRole] = "speed";
    roles[AccelerationRole] = "acceleration";
    roles[StatusRole] = "status";
    roles[StatusColorRole] = "statusColor";
    return roles;
}

void TelemetryModel::addRecord(double speed, double acceleration, bool isAccelerating)
{
    QString statusStr = "Idle";
    QString statusColor = "#506580";

    if (speed >= 180.0) {
        statusStr = "Redline Peak";
        statusColor = "#ff1a53";
    } else if (isAccelerating && speed > 0.0) {
        statusStr = "Accelerating";
        statusColor = "#00f0ff";
    } else if (speed > 0.0) {
        statusStr = "Decelerating";
        statusColor = "#ffaa00";
    }

    TelemetryRecord record;
    record.id = m_nextId++;
    record.timestamp = QDateTime::currentDateTime().toString("hh:mm:ss");
    record.speed = qRound(speed * 10.0) / 10.0;
    record.acceleration = qRound(acceleration * 10.0) / 10.0;
    record.status = statusStr;
    record.statusColor = statusColor;

    beginInsertRows(QModelIndex(), 0, 0);
    m_records.prepend(record);
    endInsertRows();

    // Maintain max 150 items
    if (m_records.count() > 150) {
        beginRemoveRows(QModelIndex(), m_records.count() - 1, m_records.count() - 1);
        m_records.removeLast();
        endRemoveRows();
    }

    emit countChanged();
}

void TelemetryModel::clearLogs()
{
    beginResetModel();
    m_records.clear();
    m_nextId = 1;
    endResetModel();
    emit countChanged();
}
