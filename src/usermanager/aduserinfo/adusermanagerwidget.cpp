/*
 ****************************************************************************
 * ADUserManagerWidget.cpp
 *
 * Created on: 2012-10-19
 *     Author: 贺辉
 *    License: LGPL
 *    Comment:
 *
 *
 *    =============================  Usage  =============================
 *|
 *|
 *    ===================================================================
 *
 *
 * This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
 * WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 ****************************************************************************
 */

/*
 ***************************************************************************
 * Last Modified on: 2012-10-19
 * Last Modified by: 贺辉
 ***************************************************************************
 */



//#ifndef DOMAIN_NAME
//#define DOMAIN_NAME "sitoy.group"
//#endif
//#ifndef DOMAIN_DEFAULTNAMINGCONTEXT
//#define DOMAIN_DEFAULTNAMINGCONTEXT "DC=sitoy,DC=group"
//#endif

#ifndef DOMAIN_DC_IP
#define DOMAIN_DC_IP "200.200.198.198"
#endif
#ifndef DOMAIN_ADMIN_NAME
#define DOMAIN_ADMIN_NAME "hehui"
#endif
#ifndef DOMAIN_ADMIN_PASSWORD
#define DOMAIN_ADMIN_PASSWORD "000..."
#endif

#ifndef ADSI_LIB
#define ADSI_LIB "adsi.dll"
#endif


#include <QMessageBox>
#include <QDebug>
#include <QKeyEvent>
#include <QMenu>
#include <QInputDialog>
#include <QTime>

#include "adusermanagerwidget.h"
#include "aduserinfowidget.h"

#include "HHSharedGUI/hdataoutputdialog.h"




namespace HEHUI {

ADUserManagerWidget::ADUserManagerWidget(QWidget *parent) :
    QWidget(parent)
{
    ui.setupUi(this);

    ui.lineEditServerIP->setText(DOMAIN_DC_IP);

    m_adsi = new ADSI(this);
    m_adOpened = false;

    m_selectedADUser = 0;

    m_defaultNamingContext = "";

    m_userInfoModel = new ADUserInfoModel(this);
    m_sortFilterProxyModel = new ADUserInfoSortFilterProxyModel(this);
    m_sortFilterProxyModel->setSourceModel(m_userInfoModel);
    ui.tableViewADUsers->setModel(m_sortFilterProxyModel);


    ui.comboBoxQueryMode->setCurrentIndex(0);
    ui.stackedWidget->setCurrentWidget(ui.pageSimpleQuery);

    ui.lineEditFilter->setText("(&(objectcategory=person)(objectclass=user)(sAMAccountName=*)(displayName=*))");
    ui.lineEditDataToRetrieve->setText("sAMAccountName,displayName");

    ui.lineEditADAdminName->setFocus();

    this->installEventFilter(this);
    ui.tableViewADUsers->installEventFilter(this);

    connect(ui.tableViewADUsers, SIGNAL(customContextMenuRequested(QPoint)), this, SLOT(slotShowCustomContextMenu(QPoint)));
    connect(ui.tableViewADUsers, SIGNAL(clicked(const QModelIndex &)), this, SLOT(getSelectedADUser(const QModelIndex &)));
    //connect(ui.tableViewADUsers->selectionModel(), SIGNAL(currentRowChanged(QModelIndex &,QModelIndex &)), this, SLOT(slotShowUserInfo(const QModelIndex &)));
    connect(ui.tableViewADUsers, SIGNAL(doubleClicked(const QModelIndex &)), this, SLOT(slotViewADUserInfo(const QModelIndex &)));


    activityTimer = new QTimer(this);
    activityTimer->setSingleShot(false);
    activityTimer->setInterval(120000); //2minutes
    connect(activityTimer, SIGNAL(timeout()), this, SLOT(activityTimeout()));
    activityTimer->start();

    m_verified = true;


//    QStringList wordList;
//    wordList << "accountExpires" << "badPasswordTime" << "badPwdCount" << "cn" << "codePage" << "countryCode";
//    wordList << "description" << "displayName" << "distinguishedName" << "dSCorePropagationData";
//    wordList << "instanceType" << "lastLogoff" << "lastLogon" << "lastLogonTimestamp" << "lockoutTime" << "logonCount";
//    wordList << "mail" << "memberOf" << "msDS-SupportedEncryptionTypes" << "name" << "nTSecurityDescriptor" ;
//    wordList << "objectCategory" << "objectClass" << "objectGUID" << "objectSid" << "primaryGroupID" << "pwdLastSet";
//    wordList << "sAMAccountName" << "sAMAccountType" << "userAccountControl" << "userPrincipalName" << "userWorkstations";
//    wordList << "uSNChanged" << "uSNCreated" << "whenChanged" << "whenCreated";



}

ADUserManagerWidget::~ADUserManagerWidget(){
    qDebug()<<"--ADUserManagerWidget::~ADUserManagerWidget()";

    if(m_adOpened){
        m_adsi->AD_Close();
    }
    m_adsi->unloadLibrary();
    delete m_adsi;

    activityTimer->stop();
    delete activityTimer;
    activityTimer = 0;

}

bool ADUserManagerWidget::eventFilter(QObject *obj, QEvent *event) {

    switch(event->type()){
    case QEvent::KeyRelease:
    {
        QKeyEvent *keyEvent = static_cast<QKeyEvent *> (event);

        if(keyEvent->key() == Qt::Key_Up || keyEvent->key() == Qt::Key_Down){
            getSelectedADUser(ui.tableViewADUsers->currentIndex());
        }

        if(keyEvent->key() == Qt::Key_Escape){
            if(ui.comboBoxQueryMode->currentIndex() == 0){
                if(ui.lineEditAccountName->hasFocus()){
                    ui.lineEditAccountName->clear();
                    ui.lineEditDisplayName->clear();
                    ui.comboBoxOU->setCurrentIndex(0);
                }//else{
                ui.lineEditAccountName->setFocus();
                //}
            }else{
                if(ui.lineEditFilter->hasFocus()){
                    ui.lineEditFilter->clear();
                    ui.lineEditDataToRetrieve->clear();
                    ui.comboBoxOU->setCurrentIndex(0);
                }//else{
                ui.lineEditFilter->setFocus();
                //}
            }

        }

        if(QApplication::keyboardModifiers() == Qt::ControlModifier && keyEvent->key() == Qt::Key_O){
            slotExportQueryResult();
        }
        if(QApplication::keyboardModifiers() == Qt::ControlModifier && keyEvent->key() == Qt::Key_P){
            slotPrintQueryResult();
        }
        if(QApplication::keyboardModifiers() == Qt::ControlModifier && keyEvent->key() == Qt::Key_E){
            //getSelectedADUser(ui.tableViewADUsers->currentIndex());
            slotViewADUserInfo(ui.tableViewADUsers->currentIndex());
        }
//        if(QApplication::keyboardModifiers() == Qt::ControlModifier && keyEvent->key() == Qt::Key_Return){
//            on_toolButtonQueryAD_clicked();
//        }

        activityTimer->start();
        return true;
    }
        break;
    case QEvent::MouseButtonPress:
    case QEvent::Leave:
    {
        activityTimer->start();
        //return QObject::eventFilter(obj, event);
    }
        break;
        //    case QEvent::ToolTip:
        //    {
        //        if(obj == ui.userPSWDLineEdit){
        //            QString pwd = ui.userPSWDLineEdit->text();
        //            if(pwd.isEmpty()){pwd = tr("Password");}
        //            QHelpEvent *helpEvent = static_cast<QHelpEvent *>(event);
        //            QString tip = QString("<b><h1>%1</h1></b>").arg(pwd);
        //            QToolTip::showText(helpEvent->globalPos(), tip);
        //            return true;
        //        }

        //    }
        //        break;
    default:
        break;
        //return QObject::eventFilter(obj, event);


    }

    return QObject::eventFilter(obj, event);

}

void ADUserManagerWidget::changeEvent(QEvent *e)
{
    QWidget::changeEvent(e);
    switch (e->type()) {
    case QEvent::LanguageChange:
        ui.retranslateUi(this);
        break;
    default:
        break;
    }
}

void ADUserManagerWidget::on_toolButtonConnect_clicked(){
    qDebug()<<"--ADUserInfo::on_ui_toolButtonConnect_clicked()";

    ui.toolButtonConnect->setEnabled(false);
    //    qApp->processEvents();

    if(m_adOpened){
        m_adsi->AD_Close();
        m_adsi->unloadLibrary();
        ui.groupBoxADUsersList->setEnabled(false);
        ui.comboBoxOU->clear();
        m_adOpened = false;
        return;
    }


    if ( (!m_adsi->isLibraryLoaded()) && (!m_adsi->loadLibrary(ADSI_LIB)) ){
        QMessageBox::critical(this, tr("Error"), tr("Failed to load ADSI library! \r\n %1").arg(m_adsi->lastErrorString()) );
        m_adsi->unloadLibrary();
        ui.toolButtonConnect->setEnabled(true);
        return;
    }

    QString serverIP = ui.lineEditServerIP->text().trimmed();
    QString adminName = ui.lineEditADAdminName->text().trimmed();
    if(adminName.isEmpty()){adminName = DOMAIN_ADMIN_NAME;}
    QString password = ui.lineEditPassword->text().trimmed();
    if(password.isEmpty()){password = DOMAIN_ADMIN_PASSWORD;}

    m_adOpened = m_adsi->AD_Open(adminName, password, serverIP);
    if(!m_adOpened){
        QMessageBox::critical(this, tr("Error"), tr("Failed to connect to DC! \r\n %1").arg(m_adsi->AD_GetLastErrorString()) );
        ui.toolButtonConnect->setEnabled(true);
        return;
    }


    m_defaultNamingContext = m_adsi->AD_DefaultNamingContext();
    ADUser::setADDefaultNamingContext( m_defaultNamingContext );

    ui.lineEditAccountName->setText(m_adsi->UserNameOfCurrentThread());

    updateOUList();

    ui.groupBoxADUsersList->setEnabled(true);

    ui.lineEditAccountName->setFocus();

}

void ADUserManagerWidget::on_comboBoxQueryMode_currentIndexChanged( int index ){
    if(index == 0){
        ui.stackedWidget->setCurrentWidget(ui.pageSimpleQuery);
    }else{
        ui.stackedWidget->setCurrentWidget(ui.pageCustomQuery);
    }
}

void ADUserManagerWidget::on_toolButtonQueryAD_clicked(){

    if(!verifyPrivilege()){
        return;
    }

    QString itemSeparator = "\\", attributeSeparator = "|";

    QString filter, dataToRetrieve;
    if(ui.comboBoxQueryMode->currentIndex() == 0){
        QString displayName = ui.lineEditDisplayName->text();
        filter = QString("(&(objectcategory=person)(objectclass=user)(sAMAccountName=%1*)%2)").arg(ui.lineEditAccountName->text()).arg(displayName.trimmed().isEmpty()?"":QString("(displayName=%1*)").arg(displayName));
        //dataToRetrieve = "sAMAccountName,displayName,telephoneNumber,description,department,title,userWorkstations,objectGUID,objectSid";
        dataToRetrieve = "sAMAccountName,displayName,telephoneNumber,description,department,title,userWorkstations";
    }else{
        filter = ui.lineEditFilter->text();
        if(filter.trimmed().isEmpty()){filter = "(&(objectcategory=person)(objectclass=user)(sAMAccountName=*)(displayName=*))";}
        dataToRetrieve = ui.lineEditDataToRetrieve->text().trimmed();
        if(dataToRetrieve.trimmed().isEmpty()){dataToRetrieve = "sAMAccountName,displayName";}
    }

    QString ouString = ui.comboBoxOU->currentText();
    if(ouString.contains("\\")){
        QStringList ousList = ouString.split("\\");
        ouString = "";
        while (!ousList.isEmpty()) {
            ouString = ouString + "OU=" + ousList.takeLast() + ",";
        }
        ouString += m_defaultNamingContext;
    }else if(!ouString.isEmpty()){
        ouString = "OU=" + ouString + "," + m_defaultNamingContext;
    }

    QStringList attributeNames = dataToRetrieve.split(",");
    QString resultString = "";
     bool ok = m_adsi->AD_GetObjectsInOU(&resultString, ouString, filter, dataToRetrieve, itemSeparator, attributeSeparator);
    if(!ok){
        QString error = m_adsi->AD_GetLastErrorString();
        m_userInfoModel->setADUserItems(attributeNames, QList<QStringList>());
        QMessageBox::critical(this, tr("Error"), tr("Failed to query AD!\r\n%1").arg(error) );

        return;
    }

    QStringList itemStrings = resultString.split(itemSeparator);
    QList<QStringList> items;
    foreach (QString itemString, itemStrings) {
        QStringList attributes = itemString.split(attributeSeparator);
        items.append(attributes);
    }

    m_userInfoModel->setADUserItems(attributeNames, items);

    ui.tableViewADUsers->horizontalHeader ()->resizeSections(QHeaderView::ResizeToContents);
    //ui.tableViewADUsers->resizeColumnToContents(0);
    //ui.tableViewADUsers->setColumnHidden(3, true);


}

void ADUserManagerWidget::on_actionExport_triggered(){
    slotExportQueryResult();
}

void ADUserManagerWidget::on_actionPrint_triggered(){
    slotPrintQueryResult();
}



void ADUserManagerWidget::on_actionProperties_triggered(){
    slotViewADUserInfo(ui.tableViewADUsers->currentIndex());
}

void ADUserManagerWidget::on_actionCreateNewAccount_triggered(){
    slotCreateADUser(0);
}

void ADUserManagerWidget::on_actionDeleteAccount_triggered(){

    QModelIndex index = ui.tableViewADUsers->currentIndex();
    if(!index.isValid()){
        return;
    }

    if(ui.comboBoxQueryMode->currentIndex() != 0 ){
        return;
    }

    getSelectedADUser(index);
    slotDeleteADUser();
}

void ADUserManagerWidget::on_actionRefresh_triggered(){
    slotRefresh();
}


void ADUserManagerWidget::slotExportQueryResult(){

    DataOutputDialog dlg(ui.tableViewADUsers, DataOutputDialog::EXPORT, this);
    dlg.exec();

}

void ADUserManagerWidget::slotPrintQueryResult(){

#ifndef QT_NO_PRINTER
    //TODO
    DataOutputDialog dlg(ui.tableViewADUsers, DataOutputDialog::PRINT, this);
    dlg.exec();
#endif

}

void ADUserManagerWidget::slotViewADUserInfo(const QModelIndex &index){
    if(!index.isValid()){
        return;
    }

    if(ui.comboBoxQueryMode->currentIndex() != 0 ){
        return;
    }

    getSelectedADUser(index);
    showADUserInfoWidget(m_selectedADUser);

}

void ADUserManagerWidget::slotCreateADUser(ADUser *adUser){
    showADUserInfoWidget(adUser, true);
}

void ADUserManagerWidget::slotDeleteADUser(){

    if(!m_selectedADUser){
        return;
    }

    QString sAMAccountName = m_selectedADUser->getAttribute("sAMAccountName");
    if(sAMAccountName.isEmpty()){
        QMessageBox::critical(this, tr("Error"), tr("Failed to find SAM AccountName"));
        return;
    }

    if(!m_adsi->AD_DeleteObject(sAMAccountName, "user")){
        QMessageBox::critical(this, tr("Error"), QString("Failed to delete user '%1'! \r\n %2").arg(sAMAccountName).arg(m_adsi->AD_GetLastErrorString()) );
    }else{
        QMessageBox::information(this, tr("OK"), QString("User '%1' deleted!").arg(sAMAccountName) );
    }

}

void ADUserManagerWidget::slotRefresh(){

    on_toolButtonQueryAD_clicked();
    updateOUList();
}

void ADUserManagerWidget::showADUserInfoWidget(ADUser *adUser, bool creareNewUser){
    qDebug()<<"--ADUserManagerWidget::showADUserInfoWidget(...)";

    if(!verifyPrivilege()){
        return;
    }

    QDialog dlg(this);
    QVBoxLayout vbl(&dlg);
    vbl.setContentsMargins(1, 1, 1, 1);

    ADUserInfoWidget wgt(m_adsi, adUser, &dlg);
    connect(&wgt, SIGNAL(signalChangesSaved()), this, SLOT(slotRefresh()));
    connect(&wgt, SIGNAL(signalCloseWidget()), &dlg, SLOT(accept()));
    connect(activityTimer, SIGNAL(timeout()), &dlg, SLOT(accept()));

    vbl.addWidget(&wgt);
    dlg.setLayout(&vbl);
    dlg.updateGeometry();
    if(creareNewUser){
        dlg.setWindowTitle(tr("Create New AD User"));
    }else{
        dlg.setWindowTitle(tr("AD User Info"));
    }
    dlg.exec();

}


void ADUserManagerWidget::slotResetADUserPassword(){

    QString sAMAccountName = m_selectedADUser->getAttribute("sAMAccountName");
    if(sAMAccountName.isEmpty()){
        QMessageBox::critical(this, tr("Error"), tr("Failed to find SAM AccountName"));
        return;
    }

    QString newPassword = "";
    bool ok = false;
    do {
        QString text = QInputDialog::getText(this, tr("Reset Password"),
                                             tr("New Password(8 Characters MIN.):"), QLineEdit::Password,
                                             "", &ok);
        if (ok && !text.isEmpty()){
            newPassword = text.trimmed();
            if(newPassword.size() < 8){
                QMessageBox::critical(this, tr("Error"), tr("At least 8 characters are required fro the password!"));
            }else{
                break;
            }
        }else{
            return;
        }

    } while (ok);

    ok = false;
    do {
        QString text = QInputDialog::getText(this, tr("Reset Password"),
                                             tr("Confirm Password:"), QLineEdit::Password,
                                             "", &ok);
        if (ok && !text.isEmpty()){
            if(newPassword != text.trimmed() ){
                QMessageBox::critical(this, tr("Error"), tr("Passwords do not match!"));
            }else{
                break;
            }
        }else{
            return;
        }

    } while (ok);


    if(!m_adsi->AD_SetPassword(sAMAccountName, newPassword)){
        QMessageBox::critical(this, tr("Error"), QString("Failed to reset password for user '%1'! \r\n %2").arg(sAMAccountName).arg(m_adsi->AD_GetLastErrorString()) );
    }else{
        QMessageBox::information(this, tr("OK"), QString("Password has been reset for user '%1'!").arg(sAMAccountName) );
    }


}

void ADUserManagerWidget::slotShowCustomContextMenu(const QPoint & pos){

    if(!verifyPrivilege()){
        return;
    }

    QTableView *tableView = qobject_cast<QTableView*> (sender());

    if (!tableView){
        return;
    }

    updateActions();

    QMenu menu(this);
    menu.addAction(ui.actionExport);

#ifndef QT_NO_PRINTER

    //menu.addSeparator();

    ui.actionPrint->setShortcut(QKeySequence::Print);
    menu.addAction(ui.actionPrint);

    //	ui.actionPrintPreview->setShortcut(Qt::CTRL + Qt::Key_P);
    //  menu.addAction(ui.actionPrintPreview);

#endif

    //#ifdef Q_OS_WIN32

    if(ui.comboBoxQueryMode->currentIndex() == 1){
        menu.exec(tableView->viewport()->mapToGlobal(pos));
        return;
    }


    menu.addSeparator();

    QMenu accountMenu(tr("Account"), this);
    accountMenu.addAction(ui.actionProperties);
    accountMenu.addSeparator();
    accountMenu.addAction(ui.actionCreateNewAccount);
    accountMenu.addAction(ui.actionDeleteAccount);
    menu.addMenu(&accountMenu);

    menu.addAction(ui.actionRefresh);

    //#endif

    menu.exec(tableView->viewport()->mapToGlobal(pos));

}

void ADUserManagerWidget::updateActions() {

    //bool enableExp = ui.tableViewADUsers->currentIndex().isValid() && ui.tableViewADUsers->selectionModel()->selectedIndexes().size();
    bool enableExp = m_userInfoModel->rowCount();
    ui.actionExport->setEnabled(enableExp);
    ui.actionPrint->setEnabled(enableExp);

    bool enableModify = false;
    bool userSelected = false;
    if(m_selectedADUser && verifyPrivilege() ){
        QString accountName = m_selectedADUser->getAttribute("sAMAccountName");
        if(!accountName.isEmpty()){
            QString distinguishedName = m_adsi->AD_GetObjectAttribute(accountName, "distinguishedName");
            if(!distinguishedName.contains("CN=Users")){
                enableModify = true;
            }
            userSelected = true;
        }
    }

    ui.actionProperties->setEnabled(userSelected);
    ui.actionCreateNewAccount->setEnabled(true);
    ui.actionDeleteAccount->setEnabled(enableModify);

    //    if(!m_isJoinedToDomain){
    //        ui.actionAutoLogon->setEnabled(enableExp && (wm->localUsers().contains(UserID(), Qt::CaseInsensitive)) ) ;
    //    }


}

void ADUserManagerWidget::getSelectedADUser(const QModelIndex &index){

    if(!index.isValid()){
        m_selectedADUser = 0;
        return;
    }

    m_selectedADUser = m_userInfoModel->getADUser(index);
}

void ADUserManagerWidget::activityTimeout(){
    m_verified = false;
}

bool ADUserManagerWidget::verifyPrivilege(){

    if(m_verified){
        return true;
    }

    bool ok = false;
    do {
        QString text = QInputDialog::getText(this, tr("Authentication Required"),
                                             tr("Authorization Number:"), QLineEdit::NoEcho,
                                             "", &ok);
        if (ok && !text.isEmpty()){
            QString accessCodeString = "";
            accessCodeString.append(QTime::currentTime().toString("hhmm"));
            if(text.toLower() == accessCodeString){
                m_verified = true;
                return true;
            }
        }

        QMessageBox::critical(this, tr("Error"), tr("Incorrect Authorization Number!"));

    } while (ok);

    return false;

}


void ADUserManagerWidget::updateOUList(){

    QString curOU = ui.comboBoxOU->currentText();

    ui.comboBoxOU->clear();
    ui.comboBoxOU->addItem("");
    QString ous = m_adsi->AD_GetAllOUs("", ";", "\\");
    QStringList ouList = ous.split(";");
    ouList.sort();
    ui.comboBoxOU->addItems(ouList);
    ui.comboBoxOU->setCurrentIndex(ui.comboBoxOU->findText(curOU));

    ADUser::setOUList(ouList);

}











} //namespace HEHUI
