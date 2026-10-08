#include "SpeedometerController.h"
#include <QtMath>
#include <QDebug>
#include <QFile>
#include <QTextStream>

SpeedometerController::SpeedometerController(QObject *parent)
    : QObject(parent)
    , m_speed(0.0)
    , m_prevSpeed(0.0)
    , m_distance(0.0)
    , m_rpm(0.0)
    , m_gear("P")
    , m_acceleration(0.0)
    , m_isAccelerating(false)
    , m_isBraking(false)
    , m_isLoggingActive(true)
    , m_peakSpeed(0.0)
    , m_avgSpeed(0.0)
    , m_totalSpeedSum(0.0)
    , m_physicsTimer(new QTimer(this))
    , m_sampleTimer(new QTimer(this))
    , m_telemetryModel(new TelemetryModel(this))
    , m_matlabExporter(new MatlabExporter(this))
{
    connect(m_physicsTimer, &QTimer::timeout, this, &SpeedometerController::updatePhysics);
    m_physicsTimer->start(16); // ~60 FPS

    connect(m_sampleTimer, &QTimer::timeout, this, &SpeedometerController::sampleTelemetry);
    m_sampleTimer->start(400); // 400ms sampling rate
}

void SpeedometerController::setSpeed(double speed)
{
    speed = qBound(0.0, speed, maxSpeed());
    if (!qFuzzyCompare(m_speed, speed)) {
        m_speed = speed;
        updateRpmAndGear();
        emit speedChanged();
    }
}

void SpeedometerController::setIsAccelerating(bool value)
{
    if (m_isAccelerating != value) {
        m_isAccelerating = value;
        emit isAcceleratingChanged();
    }
}

void SpeedometerController::setIsBraking(bool value)
{
    if (m_isBraking != value) {
        m_isBraking = value;
        emit isBrakingChanged();
    }
}

void SpeedometerController::setIsLoggingActive(bool active)
{
    if (m_isLoggingActive != active) {
        m_isLoggingActive = active;
        emit loggingActiveChanged();
    }
}

void SpeedometerController::applyPresetSpeed(double preset)
{
    setSpeed(preset);
    setIsAccelerating(false);
}

void SpeedometerController::brakeStep()
{
    setIsAccelerating(false);
    setSpeed(qMax(0.0, m_speed - 8.0));
}

void SpeedometerController::clearLogs()
{
    m_telemetryModel->clearLogs();
    m_speedHistory.clear();
    m_distanceHistory.clear();
    m_accelHistory.clear();
    m_distance = 0.0;
    m_peakSpeed = 0.0;
    m_avgSpeed = 0.0;
    m_totalSpeedSum = 0.0;
    emit distanceChanged();
    emit statsChanged();
    emit speedHistoryChanged();
}

QString SpeedometerController::exportMatlabScript()
{
    return m_matlabExporter->generateMatlabScript(m_telemetryModel);
}

QString SpeedometerController::exportCsvSheets()
{
    QString csv = "Log ID,Timestamp,Speed (KM/H),Acceleration (m/s^2),Status\n";
    const auto &records = m_telemetryModel->records();
    for (const auto &rec : records) {
        csv += QString("#%1,%2,%3,%4,%5\n")
               .arg(rec.id)
               .arg(rec.timestamp)
               .arg(rec.speed, 0, 'f', 1)
               .arg(rec.acceleration, 0, 'f', 1)
               .arg(rec.status);
    }
    return csv;
}

bool SpeedometerController::saveCsvToFile(const QString &filePath)
{
    QString cleanPath = filePath;
    if (cleanPath.startsWith("file:///")) {
        cleanPath = cleanPath.mid(8);
    }
    QFile file(cleanPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;
    QTextStream out(&file);
    out << exportCsvSheets();
    file.close();
    return true;
}

void SpeedometerController::updatePhysics()
{
    if (m_isAccelerating) {
        if (m_speed < maxSpeed()) {
            setSpeed(qMin(maxSpeed(), m_speed + 3.2));
        }
    } else {
        if (m_speed > 0.0) {
            double decayRate = qMax(0.18, m_speed * 0.014 + 0.22);
            setSpeed(qMax(0.0, m_speed - decayRate));
        } else {
            setSpeed(0.0);
        }
    }

    // Instantaneous acceleration (m/s^2) calculation
    double deltaV_ms = (m_speed - m_prevSpeed) / 3.6;
    double dt = 0.016; // 16ms
    m_acceleration = deltaV_ms / dt;
    m_prevSpeed = m_speed;

    // Distance integration x(t) = integral(v dt) in meters
    double v_ms = m_speed / 3.6;
    m_distance += v_ms * dt;

    emit accelerationChanged();
    emit distanceChanged();
}

void SpeedometerController::sampleTelemetry()
{
    if (!m_isLoggingActive) return;

    double spdVal = qRound(m_speed * 10.0) / 10.0;
    double distVal = qRound(m_distance * 10.0) / 10.0;
    double accelVal = qRound(m_acceleration * 10.0) / 10.0;

    // Update Stats
    if (spdVal > m_peakSpeed) {
        m_peakSpeed = spdVal;
    }
    m_totalSpeedSum += spdVal;
    int count = m_telemetryModel->rowCount() + 1;
    m_avgSpeed = qRound((m_totalSpeedSum / count) * 10.0) / 10.0;

    // Record into Model
    m_telemetryModel->addRecord(m_speed, m_acceleration, m_isAccelerating);

    // Buffer chart history points (up to 40 samples)
    m_speedHistory.append(spdVal);
    if (m_speedHistory.count() > 40) {
        m_speedHistory.removeFirst();
    }

    m_distanceHistory.append(distVal);
    if (m_distanceHistory.count() > 40) {
        m_distanceHistory.removeFirst();
    }

    m_accelHistory.append(accelVal);
    if (m_accelHistory.count() > 40) {
        m_accelHistory.removeFirst();
    }

    emit statsChanged();
    emit speedHistoryChanged();
}

void SpeedometerController::updateRpmAndGear()
{
    if (m_speed == 0.0) {
        m_gear = "P";
        m_rpm = 0.0;
    } else if (m_speed <= 35.0) {
        m_gear = "1";
        m_rpm = m_speed * 140.0 + 800.0;
    } else if (m_speed <= 70.0) {
        m_gear = "2";
        m_rpm = (m_speed - 35.0) * 100.0 + 1800.0;
    } else if (m_speed <= 110.0) {
        m_gear = "3";
        m_rpm = (m_speed - 70.0) * 85.0 + 2000.0;
    } else if (m_speed <= 150.0) {
        m_gear = "4";
        m_rpm = (m_speed - 110.0) * 75.0 + 2200.0;
    } else if (m_speed <= 190.0) {
        m_gear = "5";
        m_rpm = (m_speed - 150.0) * 65.0 + 2400.0;
    } else {
        m_gear = "6";
        m_rpm = (m_speed - 190.0) * 60.0 + 2600.0;
    }

    m_rpm = qMin(8000.0, m_rpm);

    emit rpmChanged();
    emit gearChanged();
}
