#ifndef DNSLOOKUP_H
#define DNSLOOKUP_H

#include <QWidget>
#include <QDnsLookup>
#include <QLineEdit>
#include <QNetworkAccessManager>


namespace Ui {
class DnsLookup;
}

namespace HEHUI {


class DnsLookupWidget : public QWidget
{
    Q_OBJECT

public:
    explicit DnsLookupWidget(QWidget *parent = 0);
    ~DnsLookupWidget();



private slots:
    void on_pushButtonLookup_clicked();

    void handleServers();

    void getIPLocation(const QString &ip);
    void replyFinished(QNetworkReply *reply);

    void showResult();

private:
    Ui::DnsLookup *ui;

    QString m_domainName;
    QString ispCT, ispCU, ispCM, isp114, ispAliDNS, ispGoogle, ispopenDNS, ispCustom;

    QHash<QString /*Server IP*/, QString /*ISP*/> m_ispInfoHash;
    QMap<QString/*Server IP*/, QStringList /*Resul List*/> m_resultHash;
    QHash<QString /*Server IP*/, int /*response count*/> m_responseCountHash;
    QHash<QString /*result*/, QString /*location*/> m_ipLocationHash;

    QList<QDnsLookup*> m_dnsLookupList;

    QNetworkAccessManager *m_Manager;


};

} //namespace HEHUI

#endif // DNSLOOKUP_H
