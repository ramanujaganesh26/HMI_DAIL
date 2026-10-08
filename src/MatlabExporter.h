#ifndef MATLABEXPORTER_H
#define MATLABEXPORTER_H

#include <QObject>
#include <QString>
#include "TelemetryModel.h"

class MatlabExporter : public QObject
{
    Q_OBJECT

public:
    explicit MatlabExporter(QObject *parent = nullptr);

    Q_INVOKABLE QString generateMatlabScript(TelemetryModel *model);
    Q_INVOKABLE bool exportToFile(TelemetryModel *model, const QString &filePath);
};

#endif // MATLABEXPORTER_H
