#include "dnslookup.h"
#include "ui_dnslookup.h"


#include <QUrl>
#include <QMessageBox>
#include <QHostAddress>
#include <QNetworkReply>
#include <QByteArray>
#include <QJsonDocument>
#include <QJsonObject>


namespace HEHUI {


DnsLookupWidget::DnsLookupWidget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::DnsLookup)
{
    ui->setupUi(this);

    ui->comboBoxType->addItem("A", QVariant(QDnsLookup::A));
    ui->comboBoxType->addItem("AAAA", QVariant(QDnsLookup::AAAA));
    ui->comboBoxType->addItem("ANY", QVariant(QDnsLookup::ANY));
    ui->comboBoxType->addItem("CNAME", QVariant(QDnsLookup::CNAME));
    ui->comboBoxType->addItem("MX", QVariant(QDnsLookup::MX));
    ui->comboBoxType->addItem("NS", QVariant(QDnsLookup::NS));
    ui->comboBoxType->addItem("PTR", QVariant(QDnsLookup::PTR));
    ui->comboBoxType->addItem("SRV", QVariant(QDnsLookup::SRV));
    ui->comboBoxType->addItem("TXT", QVariant(QDnsLookup::TXT));
    ui->comboBoxType->setCurrentIndex(0);

    ispCT = tr("China Telecom");
    ispCU = tr("China Unicom");
    ispCM = tr("China Mobile");
    isp114 = "114";
    ispAliDNS = tr("AliDNS");
    ispGoogle = "Google";
    ispopenDNS = "openDNS";
    ispCustom = "Custom";

    m_Manager = 0;


}

DnsLookupWidget::~DnsLookupWidget()
{
    delete ui;

    delete m_Manager;

}


void DnsLookupWidget::on_pushButtonLookup_clicked(){

    QUrl url = QUrl::fromUserInput(ui->lineEditDomainName->text().trimmed());
    if(!url.isValid() || url.isLocalFile()){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Domain Name!"));
        return;
    }
    m_domainName = url.host();
    ui->lineEditDomainName->setText(m_domainName);
    ui->textBrowserResult->clear();

    m_ispInfoHash.clear();
    m_resultHash.clear();
    m_responseCountHash.clear();
    m_ipLocationHash.clear();


    if(ui->groupBoxChinaTelecom->isChecked()){
        foreach (QObject *obj, ui->groupBoxChinaTelecom->children()) {
            QCheckBox *box = qobject_cast<QCheckBox *>(obj);
            if(box && box->isChecked()){
                m_ispInfoHash.insert(box->text(), ispCT);
                m_resultHash.insert(box->text(), QStringList());
            }
        }
    }

    if(ui->groupBoxChinaUnicom->isChecked()){
        foreach (QObject *obj, ui->groupBoxChinaUnicom->children()) {
            QCheckBox *box = qobject_cast<QCheckBox *>(obj);
            if(box && box->isChecked()){
                m_ispInfoHash.insert(box->text(), ispCU);
                m_resultHash.insert(box->text(), QStringList());
            }
        }
    }

    if(ui->groupBoxChinaMobile->isChecked()){
        foreach (QObject *obj, ui->groupBoxChinaMobile->children()) {
            QCheckBox *box = qobject_cast<QCheckBox *>(obj);
            if(box && box->isChecked()){
                m_ispInfoHash.insert(box->text(), ispCM);
                m_resultHash.insert(box->text(), QStringList());
            }
        }
    }

    if(ui->groupBoxPublicDNS->isChecked()){
        foreach (QObject *obj, ui->groupBoxPublicDNS->children()) {
            QCheckBox *box = qobject_cast<QCheckBox *>(obj);
            if(box && box->isChecked()){
                //m_ispInfoHash.append(box->text(), ispName);
                m_resultHash.insert(box->text(), QStringList());
            }
        }

        if(ui->checkBox114->isChecked()){
            m_ispInfoHash.insert(ui->checkBox114->text(), isp114);
        }
        if(ui->checkBoxAliDNS->isChecked()){
            m_ispInfoHash.insert(ui->checkBoxAliDNS->text(), ispAliDNS);
        }
        if(ui->checkBoxGoogle->isChecked()){
            m_ispInfoHash.insert(ui->checkBoxGoogle->text(), ispGoogle);
        }
        if(ui->checkBoxOpenDNS->isChecked()){
            m_ispInfoHash.insert(ui->checkBoxOpenDNS->text(), ispopenDNS);
        }
    }

    if(ui->groupBoxCustom->isChecked()){
        foreach (QObject *obj, ui->groupBoxCustom->children()) {
            QLineEdit *edit = qobject_cast<QLineEdit *>(obj);
            if(edit){
                QString ip = edit->text().trimmed();
                if(!ip.isEmpty()){
                    m_ispInfoHash.insert(ip, ispCustom);
                    m_resultHash.insert(ip, QStringList());
                }
            }
        }
    }

    QStringList nameServers = m_resultHash.keys();
    if(nameServers.isEmpty()){
        QMessageBox::critical(this, tr("Error"), tr("No name server!"));
        return;
    }


//    if(!m_dnsLookup){
//        m_dnsLookup = new QDnsLookup(this);
//        connect(m_dnsLookup, SIGNAL(finished()), this, SLOT(handleServers()));
//    }

    ui->pushButtonLookup->setEnabled(false);
    ui->lineEditDomainName->setReadOnly(true);
    ui->comboBoxType->setEnabled(false);
    ui->lineEditNSIPCustom1->setReadOnly(true);
    ui->lineEditNSIPCustom2->setReadOnly(true);


    QDnsLookup::Type type = QDnsLookup::Type(ui->comboBoxType->currentData().toUInt());
    foreach (QString nameServer, nameServers) {
        m_responseCountHash.insert(nameServer, 0);

        QDnsLookup *dnsLookup = new QDnsLookup(this);
        connect(dnsLookup, SIGNAL(finished()), this, SLOT(handleServers()));

        dnsLookup->setNameserver(QHostAddress(nameServer));
        dnsLookup->setName(m_domainName);
        dnsLookup->setType(type);
        dnsLookup->lookup();
    }

}

void DnsLookupWidget::handleServers(){
    //qDebug()<<"--DnsLookup::handleServers()";


    QDnsLookup *dnsLookup = qobject_cast<QDnsLookup *>(sender());
    if(!dnsLookup){
        delete dnsLookup;
        dnsLookup = 0;
        return;
    }

    QString nameServer = dnsLookup->nameserver().toString();
    if(dnsLookup->name() != m_domainName){
        delete dnsLookup;
        dnsLookup = 0;
        return;
    }


    QStringList values = m_resultHash.value(nameServer);

    // Check the lookup succeeded.
    if (dnsLookup->error() == QDnsLookup::NoError) {
//            qDebug()<<"nameserver:"<<dnsLookup->nameserver();
//            qDebug()<<"type:"<<dnsLookup->type();
//            qDebug()<<"canonicalNameRecords() :"<<dnsLookup->canonicalNameRecords().size();
//            qDebug()<<"hostAddressRecords() :"<<dnsLookup->hostAddressRecords().size();
//            qDebug()<<"mailExchangeRecords() :"<<dnsLookup->mailExchangeRecords().size();
//            qDebug()<<"nameServerRecords() :"<<dnsLookup->nameServerRecords().size();
//            qDebug()<<"pointerRecords() :"<<dnsLookup->pointerRecords().size();
//            qDebug()<<"serviceRecords() :"<<dnsLookup->serviceRecords().size();
//            qDebug()<<"textRecords() :"<<dnsLookup->textRecords().size();

        switch (dnsLookup->type()) {
        case QDnsLookup::A:
        {
            foreach (const QDnsHostAddressRecord &record, dnsLookup->hostAddressRecords()) {
                //qWarning()<<record.name()<<" " <<record.value();
                QString result = record.value().toString();
                if(!values.contains(result)){
                    values.append(result);
                    getIPLocation(result);
                }
            }
        }
            break;
        case QDnsLookup::AAAA:
        {
            foreach (const QDnsDomainNameRecord &record, dnsLookup->canonicalNameRecords()) {
                //qWarning()<<record.name()<<" " <<record.value();
                values.append(record.value());
            }
        }
            break;
        case QDnsLookup::MX:
        {
            foreach (const QDnsMailExchangeRecord &record, dnsLookup->mailExchangeRecords()) {
                //qWarning()<<record.name()<<" " <<record.exchange();
                QString result = record.exchange();
                if(!values.contains(result)){
                    values.append(result);
                }
            }
        }
            break;
        case QDnsLookup::NS:
        case QDnsLookup::PTR:
        {
            foreach (const QDnsDomainNameRecord &record, dnsLookup->nameServerRecords()) {
                //qWarning()<<"Domain:"<<record.name()<<" "<<record.value();
                QString result = record.value();
                if(!values.contains(result)){
                    values.append(result);
                }
            }
        }
            break;
        case QDnsLookup::SRV:
        {
            foreach (const QDnsServiceRecord &record, dnsLookup->serviceRecords()) {
                //qWarning()<<"Domain:"<<record.target()<<" "<<record.name();
                QString result = record.name();
                if(!values.contains(result)){
                    values.append(result);
                }
            }
        }
            break;
        case QDnsLookup::TXT:
        {
            foreach (const QDnsTextRecord &record, dnsLookup->textRecords()) {
                //qWarning()<<"Domain:"<<record.name()<<" "<<record.values();
                foreach (QByteArray ba, record.values()) {
                    QString result = QString(ba);
                    if(!values.contains(result)){
                        values.append(result);
                    }
                }
            }
        }
            break;
        default:
            break;
        }

    }else{
        qCritical()<<"DNS lookup failed! "<<dnsLookup->errorString();
        values.append(dnsLookup->errorString());
    }

    m_resultHash[nameServer] = values;

    showResult();


    int count = m_responseCountHash.value(nameServer) + 1;
    if(count < ui->spinBoxRepeat->value()){
        dnsLookup->lookup();
        m_responseCountHash[nameServer] = count;
    }else{
        delete dnsLookup;
        dnsLookup = 0;
    }


}

void DnsLookupWidget::getIPLocation(const QString &ip){
    if(!m_Manager){
        m_Manager = new QNetworkAccessManager(this);
        connect(m_Manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));
    }

    m_Manager->get(QNetworkRequest(QUrl(QString("http://ip.taobao.com/service/getIpInfo.php?ip=%1").arg(ip))));

}

void DnsLookupWidget::replyFinished(QNetworkReply *reply){


    if(reply->error() == QNetworkReply::NoError){
        QByteArray ba = reply->readAll();
        qDebug()<<"------------------------------------:"<<ba;
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(ba, &error);
        if(error.error != QJsonParseError::NoError){
            qCritical()<<error.errorString();
            reply->deleteLater();
            return;
        }
        QJsonObject obj = doc.object();
        bool err = obj["code"].toBool();
        if(err){
            reply->deleteLater();
            return;
        }
        QJsonObject dataobj = obj["data"].toObject();
        if(dataobj.isEmpty()){
            reply->deleteLater();
            return;
        }
        QString country = dataobj["country"].toString();
        //QString country_id = dataobj["country_id"].toString();
        QString region = dataobj["region"].toString();
        QString city = dataobj["city"].toString();

        QString isp = dataobj["isp"].toString();
        QString ip = dataobj["ip"].toString();

        QString location = country + " " + region + " " + city + " " + isp;
        location = location.trimmed();
        m_ipLocationHash[ip] = location;

        showResult();


    }else{
        qCritical()<<"ERROR!"<<reply->errorString();
    }

    reply->deleteLater();

}

void DnsLookupWidget::showResult(){
    QString colorString = "style=\"background-color: #ffffff;\" ";
    QString html = "<html><head><meta content=\"text/html; charset=utf-8\" http-equiv=\"Content-Type\"><title>DNS</title>"
           "<style type=\"text/css\">"
            "table{ background-color: #b2b2b2; margin-top: 1px; margin-bottom: 1px; margin-left: 1px; margin-right: 1px; width: 100%; font-size: 16px;}"
            "table tr{background-color: #f3f8fb;}"
            "</style>"
            "</head><body>"
            ;
    html += "<table  border=\"0\" cellpadding=\"5\" cellspacing=\"1\"  >"
            "<tr>"
              "<td align=\"center\" colspan=\"4\">Result</td>"
            "</tr>"
            "<tr>"
              "<td align=\"center\" valign=\"middle\" >DNS Server</td>"
              "<td width=\"200px\">Result</td>"
            ;

    bool isTypeA = (QDnsLookup::A == QDnsLookup::Type(ui->comboBoxType->currentData().toUInt()));
    //if(isTypeA){
        html += "<td width=\"200px\">Location</td>";
    //}
    html +=  "<td>PING</td>";
    html += "</tr>";

    ///////////////////////////////////

    int index = 0;
    //int indexResult = 1;

    bool done = true;
    QStringList nameServers = m_resultHash.keys();
    foreach (QString nameServer, nameServers) {
        QStringList results = m_resultHash.value(nameServer);
        if(results.size() < ui->spinBoxRepeat->value()){
            done = false;
        }
        results.removeDuplicates();
        int size = results.size();
        if(size<1){
            continue;
        }


        html += QString("<tr %1>").arg((index%2)?"":colorString);

        if(size > 1){
            html += QString("<td align=\"center\" valign=\"middle\" %1 rowspan=\"%2\">%3<p>(%4)</p></td>").arg((index%2)?"":colorString).arg(size).arg(nameServer).arg(m_ispInfoHash.value(nameServer));
            //html += QString("<td>%1</td>").arg(nameServer);
            html += QString("<td>%1</td>").arg(results.at(0));
            //if(isTypeA){
                html += QString("<td>%1</td>").arg(m_ipLocationHash.value(results.at(0)));
            //}
            html += "<td>-------0-------</td>";
            html += "</tr>";

            //index++;
            //indexResult++;
            results.removeAt(0);
            //results.sort();
            foreach (QString result, results) {
                //qDebug()<<"-------nameServer:"<<nameServer<<" result:"<<result;
                html += QString("<tr %1>").arg((index%2)?"":colorString);
                html += QString("<td valign=\"middle\">%1</td>").arg(result);
                //if(isTypeA){
                    html += QString("<td valign=\"middle\">%1</td>").arg(m_ipLocationHash.value(result));
                //}
                html += "<td>------1-------</td>";
                //indexResult++;
            }
            html += "</tr>";
            index++;
        }else{
            html += QString("<td align=\"center\" valign=\"middle\" %1>%2<p>(%3)</p></td>").arg((index%2)?"":colorString).arg(nameServer).arg(m_ispInfoHash.value(nameServer));
            html += QString("<td valign=\"middle\">%1</td>").arg(results.at(0));
            //if(isTypeA){
                html += QString("<td valign=\"middle\">%1</td>").arg(m_ipLocationHash.value(results.at(0)));
            //}
            html += "<td valign=\"middle\" >---2----</td>";
            html += "</tr>";

            index++;
            //indexResult++;
        }

    }



    html += "</table></body></html>";
    ui->textBrowserResult->setHtml(html);

    if(done){
        ui->lineEditDomainName->setReadOnly(false);
        ui->comboBoxType->setEnabled(true);
        ui->pushButtonLookup->setEnabled(true);
    }

    qDebug()<<"html:\n"<<html;

}


} //namespace HEHUI
