#include "MatlabExporter.h"
#include <QFile>
#include <QTextStream>
#include <QDateTime>

MatlabExporter::MatlabExporter(QObject *parent)
    : QObject(parent)
{
}

QString MatlabExporter::generateMatlabScript(TelemetryModel *model)
{
    if (!model) return QString();

    const auto &records = model->records();

    QString mCode;
    QTextStream out(&mCode);

    out << "% ==========================================\n";
    out << "% HMIMI Precision Speedometer - MATLAB Telemetry Script\n";
    out << "% Generated: " << QDateTime::currentDateTime().toString(Qt::ISODate) << "\n";
    out << "% ==========================================\n\n";

    QStringList times;
    QStringList speeds;

    int n = records.count();
    for (int i = n - 1; i >= 0; --i) {
        double t = (n - 1 - i) * 0.4;
        times.append(QString::number(t, 'f', 1));
        speeds.append(QString::number(records.at(i).speed, 'f', 1));
    }

    if (speeds.isEmpty()) {
        times.append("0");
        speeds.append("0");
    }

    out << "time = [" << times.join(", ") << "]; % Time (s)\n";
    out << "speed = [" << speeds.join(", ") << "]; % Speed (KM/H)\n\n";

    out << "% Convert speed (KM/H) to (m/s) for acceleration derivative\n";
    out << "speed_ms = speed ./ 3.6;\n";
    out << "dt = 0.4; % Sampler interval (s)\n";
    out << "accel = [0, diff(speed_ms) ./ dt]; % Acceleration (m/s^2)\n\n";

    out << "% 1. Plot Speed Profile v(t)\n";
    out << "figure('Name', 'HMIMI Telemetry Analysis', 'Position', [100 100 900 600], 'Color', [0.05 0.07 0.12]);\n";
    out << "subplot(2,1,1);\n";
    out << "plot(time, speed, '-o', 'LineWidth', 2, 'Color', [0 0.94 1], 'MarkerFaceColor', [0 0.94 1]);\n";
    out << "grid on;\n";
    out << "title('Speed Profile v(t)', 'FontSize', 12, 'Color', 'w');\n";
    out << "xlabel('Time (seconds)', 'Color', 'w');\n";
    out << "ylabel('Speed (KM/H)', 'Color', 'w');\n";
    out << "set(gca, 'Color', [0.08 0.12 0.2], 'XColor', 'w', 'YColor', 'w');\n\n";

    out << "% 2. Plot Acceleration Derivative a(t) = dv/dt\n";
    out << "subplot(2,1,2);\n";
    out << "plot(time, accel, '-s', 'LineWidth', 2, 'Color', [1 0.1 0.3], 'MarkerFaceColor', [1 0.1 0.3]);\n";
    out << "grid on;\n";
    out << "title('Acceleration Derivative a(t) = dv/dt', 'FontSize', 12, 'Color', 'w');\n";
    out << "xlabel('Time (seconds)', 'Color', 'w');\n";
    out << "ylabel('Acceleration (m/s^2)', 'Color', 'w');\n";
    out << "set(gca, 'Color', [0.08 0.12 0.2], 'XColor', 'w', 'YColor', 'w');\n\n";

    out << "% Metrics Summary\n";
    out << "fprintf('--- MATLAB TELEMETRY ANALYSIS METRICS ---\\n');\n";
    out << "fprintf('Peak Recorded Speed: %.2f KM/H\\n', max(speed));\n";
    out << "fprintf('Mean Speed: %.2f KM/H\\n', mean(speed));\n";
    out << "fprintf('Max Acceleration: %.2f m/s^2\\n', max(accel));\n";

    return mCode;
}

bool MatlabExporter::exportToFile(TelemetryModel *model, const QString &filePath)
{
    QString content = generateMatlabScript(model);
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&file);
    out << content;
    file.close();
    return true;
}
