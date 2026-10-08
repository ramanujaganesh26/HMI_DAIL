#ifndef SPEEDOMETERCONTROLLER_H
#define SPEEDOMETERCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QAbstractItemModel>
#include <qqmlintegration.h>
#include "TelemetryModel.h"
#include "MatlabExporter.h"

class SpeedometerController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(double speed READ speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(double maxSpeed READ maxSpeed CONSTANT)
    Q_PROPERTY(double rpm READ rpm NOTIFY rpmChanged)
    Q_PROPERTY(QString gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(double acceleration READ acceleration NOTIFY accelerationChanged)
    Q_PROPERTY(bool isAccelerating READ isAccelerating WRITE setIsAccelerating NOTIFY isAcceleratingChanged)
    Q_PROPERTY(bool isBraking READ isBraking WRITE setIsBraking NOTIFY isBrakingChanged)
    Q_PROPERTY(bool isLoggingActive READ isLoggingActive WRITE setIsLoggingActive NOTIFY loggingActiveChanged)

    Q_PROPERTY(double distance READ distance NOTIFY distanceChanged)
    Q_PROPERTY(double peakSpeed READ peakSpeed NOTIFY statsChanged)
    Q_PROPERTY(double avgSpeed READ avgSpeed NOTIFY statsChanged)
    Q_PROPERTY(int recordCount READ recordCount NOTIFY statsChanged)
    Q_PROPERTY(QVariantList speedHistory READ speedHistory NOTIFY speedHistoryChanged)
    Q_PROPERTY(QVariantList distanceHistory READ distanceHistory NOTIFY speedHistoryChanged)
    Q_PROPERTY(QVariantList accelHistory READ accelHistory NOTIFY speedHistoryChanged)

    Q_PROPERTY(TelemetryModel* telemetryModel READ telemetryModel CONSTANT)
    Q_PROPERTY(MatlabExporter* matlabExporter READ matlabExporter CONSTANT)

public:
    explicit SpeedometerController(QObject *parent = nullptr);

    double speed() const { return m_speed; }
    void setSpeed(double speed);

    double maxSpeed() const { return 240.0; }
    double rpm() const { return m_rpm; }
    QString gear() const { return m_gear; }
    double acceleration() const { return m_acceleration; }

    bool isAccelerating() const { return m_isAccelerating; }
    void setIsAccelerating(bool value);

    bool isBraking() const { return m_isBraking; }
    void setIsBraking(bool value);

    bool isLoggingActive() const { return m_isLoggingActive; }
    void setIsLoggingActive(bool active);

    double distance() const { return m_distance; }
    double peakSpeed() const { return m_peakSpeed; }
    double avgSpeed() const { return m_avgSpeed; }
    int recordCount() const { return m_telemetryModel->rowCount(); }
    QVariantList speedHistory() const { return m_speedHistory; }
    QVariantList distanceHistory() const { return m_distanceHistory; }
    QVariantList accelHistory() const { return m_accelHistory; }

    TelemetryModel* telemetryModel() { return m_telemetryModel; }
    MatlabExporter* matlabExporter() { return m_matlabExporter; }

    Q_INVOKABLE void applyPresetSpeed(double preset);
    Q_INVOKABLE void brakeStep();
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE QString exportMatlabScript();
    Q_INVOKABLE QString exportCsvSheets();
    Q_INVOKABLE bool saveCsvToFile(const QString &filePath);

signals:
    void speedChanged();
    void distanceChanged();
    void rpmChanged();
    void gearChanged();
    void accelerationChanged();
    void isAcceleratingChanged();
    void isBrakingChanged();
    void loggingActiveChanged();
    void statsChanged();
    void speedHistoryChanged();

private slots:
    void updatePhysics();
    void sampleTelemetry();

private:
    void updateRpmAndGear();

    double m_speed;
    double m_prevSpeed;
    double m_distance;
    double m_rpm;
    QString m_gear;
    double m_acceleration;

    bool m_isAccelerating;
    bool m_isBraking;
    bool m_isLoggingActive;

    double m_peakSpeed;
    double m_avgSpeed;
    double m_totalSpeedSum;

    QVariantList m_speedHistory;
    QVariantList m_distanceHistory;
    QVariantList m_accelHistory;

    QTimer *m_physicsTimer;
    QTimer *m_sampleTimer;

    TelemetryModel *m_telemetryModel;
    MatlabExporter *m_matlabExporter;
};

#endif // SPEEDOMETERCONTROLLER_H
