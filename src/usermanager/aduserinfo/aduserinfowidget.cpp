

#include <QMessageBox>
#include <QDebug>


#include "aduserinfowidget.h"
#include "ui_aduserinfowidget.h"



namespace HEHUI {


ADUserInfoWidget::ADUserInfoWidget(ADSI *adsi, ADUser *adUser, QWidget *parent) :
    QWidget(parent), m_adsi(adsi)
{
    ui.setupUi(this);

    ui.groupBoxUseLocalComputer->setVisible(false);

    m_accountName = "";
    m_displayName = "";
    m_description = "";
    m_userWorkstations = "";
    m_telephone = "";
    m_department = "";
    m_title = "";
    m_guid = "";
    m_sid = "";
//    m_distinguishedName = "";
    m_simpleOUString = "";
    m_fullOUString = "";

    if(adUser){
        m_adUser = *adUser;
    }

    initUI();


}

ADUserInfoWidget::~ADUserInfoWidget()
{

}

void ADUserInfoWidget::on_pushButtonEdit_clicked(){

    if(ui.lineEditDisplayName->isReadOnly()){
        switchToEditMode();
        return;
    }

    saveChanges();

}

void ADUserInfoWidget::on_pushButtonClose_clicked(){

//    if(!ui.lineEditDisplayName->isReadOnly()){

//        QString accountName = ui.lineEditSAMAccount->text().trimmed();
//        QString displayName = ui.lineEditDisplayName->text();
//        QString description = ui.lineEditDescription->text();
//        QString userWorkstations = ui.lineEditUserWorkstations->text().trimmed();
//        QString telephone = ui.lineEditTelephone->text();
//        QString ouString = ui.comboBoxOU->currentText();

//        if(m_accountName != accountName || m_displayName != displayName
//                || m_description != description || m_userWorkstations != userWorkstations
//                || m_telephone != telephone || m_simpleOUString != ouString){

            int rep = QMessageBox::question(this, tr("Question"), tr("Do you want to save changes before quit?"), QMessageBox::Yes|QMessageBox::No, QMessageBox::Yes);
            if(rep == QMessageBox::Yes){
                saveChanges();
            }

//        }
//    }

    this->close();
    emit signalCloseWidget();

}

void ADUserInfoWidget::on_checkBoxUserMustChangePassword_clicked(){
    if(ui.checkBoxUserMustChangePassword->isChecked()){
        ui.checkBoxUserCannotChangePassword->setChecked(false);
        ui.checkBoxPasswordNeverExpires->setChecked(false);
    }
}

void ADUserInfoWidget::on_checkBoxUserCannotChangePassword_clicked(){
    if(ui.checkBoxUserCannotChangePassword->isChecked()){
        ui.checkBoxUserMustChangePassword->setChecked(false);
    }
}

void ADUserInfoWidget::on_checkBoxPasswordNeverExpires_clicked(){
    if(ui.checkBoxPasswordNeverExpires->isChecked()){
        ui.checkBoxUserMustChangePassword->setChecked(false);
    }
}

void ADUserInfoWidget::saveChanges(){

    int pos = 0;
    QRegExpValidator rxValidator(this);
    QRegExp rx;

    QString accountName = ui.lineEditSAMAccount->text().trimmed();
    rx.setPattern("^\\w+$");
    rxValidator.setRegExp(rx);
    if(rxValidator.validate(accountName, pos) != QValidator::Acceptable){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Account Name!"));
        ui.lineEditSAMAccount->setFocus();
        return ;
    }

    QString displayName = ui.lineEditDisplayName->text();
    if(displayName.contains(";") || displayName.contains("|")){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Display Name!"));
        ui.lineEditDisplayName->setFocus();
        return ;
    }

    QString description = ui.lineEditDescription->text();
    if(description.contains(";") || description.contains("|")){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Description!"));
        ui.lineEditDescription->setFocus();
        return ;
    }

    QString userWorkstations = ui.lineEditUserWorkstations->text().trimmed();
//    rx.setPattern("^(\\w+,*)+$");
//    rxValidator.setRegExp(rx);
//    if(rxValidator.validate(userWorkstations, pos) != QValidator::Acceptable){
//        QMessageBox::critical(this, tr("Error"), tr("Invalid Workstations!"));
//        ui.lineEditUserWorkstations->setFocus();
//        return ;
//    }
    if(userWorkstations.contains(";") || userWorkstations.contains("|")){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Workstations!"));
        ui.lineEditUserWorkstations->setFocus();
        return ;
    }

    QString telephone = ui.lineEditTelephone->text();
    if(telephone.contains(";") || telephone.contains("|")){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Telephone Number!"));
        ui.lineEditTelephone->setFocus();
        return ;
    }

    QString department = ui.lineEditDepartment->text();
    if(department.contains(";") || department.contains("|")){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Department!"));
        ui.lineEditDepartment->setFocus();
        return ;
    }

    QString title = ui.lineEditTitle->text();
    if(title.contains(";") || title.contains("|")){
        QMessageBox::critical(this, tr("Error"), tr("Invalid Title!"));
        ui.lineEditTitle->setFocus();
        return ;
    }

    QString ouString = ui.comboBoxOU->currentText();
    if( (!m_simpleOUString.isEmpty()) && (ouString.isEmpty()) ){
        QMessageBox::critical(this, tr("Error"), tr("Invalid OU!"));
        ui.comboBoxOU->setFocus();
        return ;
    }

    QString password = ui.lineEditPassword->text();
    if(password != ui.lineEditConfirmPassword->text()){
        QMessageBox::critical(this, tr("Error"), tr("Passwords do not match!"));
        return;
    }


    m_fullOUString = ouString;
    if(m_fullOUString.contains("\\")){
        QStringList ousList = m_fullOUString.split("\\");
        m_fullOUString = "";
        while (!ousList.isEmpty()) {
            m_fullOUString = m_fullOUString + "OU=" + ousList.takeLast() + ",";
        }
        m_fullOUString += ADUser::getADDefaultNamingContext();
    }else if(!m_fullOUString.isEmpty()){
        m_fullOUString = "OU=" + m_fullOUString + "," + ADUser::getADDefaultNamingContext();
    }

    bool ok = false;
    bool saved = true;

    if(m_accountName != accountName){
        ok = m_adsi->AD_CreateUser(m_fullOUString, accountName, "");
        if(!ok){
            QMessageBox::critical(this, tr("Error"), tr("Failed to create new account! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            return;
        }

        m_accountName = accountName;
        ui.lineEditSAMAccount->setReadOnly(true);

        m_guid = m_adsi->AD_GetObjectAttribute(accountName, "objectGUID");
        m_adUser.setAttribute("objectGUID", m_guid);
        m_sid = m_adsi->AD_GetObjectAttribute(accountName, "objectSid");
        m_adUser.setAttribute("objectSid", m_sid);

        ui.lineEditGUID->setText(m_guid);
//        ui.lineEditGUID->show();
        ui.lineEditSID->setText(m_sid);
//        ui.lineEditSID->show();

        if(password.isEmpty()){
            QMessageBox::critical(this, tr("Error"), tr("Password is required!"));
            ui.lineEditPassword->setFocus();
            return;
        }

        ui.pushButtonEdit->setText(tr("&Save"));
    }

    if(!password.isEmpty()){
        ok = m_adsi->AD_SetPassword(accountName, password);
        if(!ok){
            QMessageBox::critical(this, tr("Error"), QString("Failed to set password for user '%1'! \r\n %2").arg(accountName).arg(m_adsi->AD_GetLastErrorString()) );
            saved = false;
        }
    }

    if(m_displayName != displayName){
        ok = m_adsi->AD_ModifyAttribute(accountName, "displayName", displayName, 0);
        if(!ok){
            m_displayName = m_adsi->AD_GetObjectAttribute(accountName, "displayName");
            ui.lineEditDisplayName->setText(m_displayName);
            QMessageBox::critical(this, tr("Error"), tr("Failed to update display name! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_displayName = displayName;
        }
    }

    if(m_description != description){
        ok = m_adsi->AD_ModifyAttribute(accountName, "description", description, 0);
        if(!ok){
            m_description = m_adsi->AD_GetObjectAttribute(accountName, "description");
            ui.lineEditDescription->setText(m_description);
            QMessageBox::critical(this, tr("Error"), tr("Failed to update description! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_description = description;
        }
    }

    if(m_userWorkstations != userWorkstations){
        ok = m_adsi->AD_ModifyAttribute(accountName, "userWorkstations", userWorkstations);
        if(!ok){
            m_userWorkstations = m_adsi->AD_GetObjectAttribute(accountName, "userWorkstations");
            ui.lineEditUserWorkstations->setText(m_userWorkstations);
            QMessageBox::critical(this, tr("Error"), tr("Failed to update user workstations! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_userWorkstations = userWorkstations;
        }
    }

    if(m_telephone != telephone){
        ok = m_adsi->AD_ModifyAttribute(accountName, "telephoneNumber", telephone, 0);
        if(!ok){
            m_telephone = m_adsi->AD_GetObjectAttribute(accountName, "telephoneNumber");
            ui.lineEditTelephone->setText(m_telephone);
            QMessageBox::critical(this, tr("Error"), tr("Failed to update telephone number! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_telephone = telephone;
        }
    }

    if(m_department != department){
        ok = m_adsi->AD_ModifyAttribute(accountName, "department", department, 0);
        if(!ok){
            m_department = m_adsi->AD_GetObjectAttribute(accountName, "department");
            ui.lineEditDepartment->setText(m_department);
            QMessageBox::critical(this, tr("Error"), tr("Failed to update department ! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_department = department;
        }
    }

    if(m_title != title){
        ok = m_adsi->AD_ModifyAttribute(accountName, "title", title, 0);
        if(!ok){
            m_department = m_adsi->AD_GetObjectAttribute(accountName, "title");
            ui.lineEditTitle->setText(title);
            QMessageBox::critical(this, tr("Error"), tr("Failed to update title ! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_title = title;
        }
    }

    if( (m_simpleOUString != ouString) && (!ouString.isEmpty()) ){
        ok = m_adsi->AD_MoveObject(m_fullOUString, accountName);
        if(!ok){
            ui.comboBoxOU->setCurrentIndex(ui.comboBoxOU->findText(m_simpleOUString));
            QMessageBox::critical(this, tr("Error"), tr("Failed to move user! \r\n %1").arg(m_adsi->AD_GetLastErrorString()));
            saved = false;
        }else{
            m_simpleOUString = ouString;
        }
    }

    bool accountDisabled = ui.checkBoxAccountDisabled->isChecked();
    if(m_adsi->accountDisabled(accountName) != accountDisabled){
        ok = m_adsi->AD_EnableObject(accountName, !accountDisabled);
        if(!ok){
            QMessageBox::critical(this, tr("Error"), QString("Failed to %1 user '%2'! \r\n %3").arg((!accountDisabled)?tr("enable"):tr("disable")).arg(accountName).arg(m_adsi->AD_GetLastErrorString()) );
            saved = false;
        }
    }

    if(ui.checkBoxUnlockAccount->isChecked()){
        ok = m_adsi->AD_UnlockObject(accountName);
        if(!ok){
            QMessageBox::critical(this, tr("Error"), QString("Failed to unlock user '%1'! \r\n %2").arg(accountName).arg(m_adsi->AD_GetLastErrorString()) );
            saved = false;
        }
    }

    bool userMustChangePassword = ui.checkBoxUserMustChangePassword->isChecked();
    if(userMustChangePassword != m_adsi->userMustChangePassword(accountName)){
        ok = m_adsi->AD_ModifyAttribute(accountName, "pwdLastSet", userMustChangePassword?"0":"-1");
        if(!ok){
            QMessageBox::critical(this, tr("Error"), QString("Operation Failed! \r\n %1").arg(accountName).arg(m_adsi->AD_GetLastErrorString()) );
            saved = false;
        }
    }

    bool userCannotChangePassword = ui.checkBoxUserCannotChangePassword->isChecked();
    if(userCannotChangePassword != m_adsi->userCannotChangePassword(accountName)){
        ok = m_adsi->AD_SetUserCannotChangePassword(accountName, userCannotChangePassword);
        if(!ok){
            QMessageBox::critical(this, tr("Error"), QString("Operation Failed! \r\n %1").arg(accountName).arg(m_adsi->AD_GetLastErrorString()) );
            saved = false;
        }
    }

    bool passwordNeverExpires = ui.checkBoxPasswordNeverExpires->isChecked();
    if(passwordNeverExpires != m_adsi->passwordNeverExpires(accountName)){
        ok = m_adsi->AD_SetPasswordExpire(accountName, !passwordNeverExpires);
        if(!ok){
            QMessageBox::critical(this, tr("Error"), QString("Operation Failed! \r\n %1").arg(accountName).arg(m_adsi->AD_GetLastErrorString()) );
            saved = false;
        }
    }


    if(saved){
        switchToViewMode();
    }

    emit signalChangesSaved();

}


void ADUserInfoWidget::initUI(){
    qDebug()<<"--ADUserInfoWidget::initUI()";

    m_accountName = m_adUser.getAttribute("sAMAccountName");
    ui.comboBoxOU->addItem("");
    ui.comboBoxOU->addItems(ADUser::getOUList());

    if(m_accountName.isEmpty()){
        switchToCreatingMode();
        return;
    }

    switchToViewMode();

    ui.lineEditSAMAccount->setText(m_accountName);

    m_displayName = m_adUser.getAttribute("displayName");
    ui.lineEditDisplayName->setText(m_displayName);

    m_userWorkstations = m_adUser.getAttribute("userWorkstations").toUpper();
    ui.lineEditUserWorkstations->setText(m_userWorkstations);

    m_description = m_adUser.getAttribute("description");
    ui.lineEditDescription->setText(m_description);

    m_telephone = m_adUser.getAttribute("telephoneNumber");
    ui.lineEditTelephone->setText(m_telephone);

    m_department = m_adUser.getAttribute("department");
    ui.lineEditDepartment->setText(m_department);

    m_title = m_adUser.getAttribute("title");
    ui.lineEditTitle->setText(m_title);

    QString m_cn = m_adsi->AD_GetObjectAttribute(m_accountName, "cn");
    QString m_distinguishedName = m_adsi->AD_GetObjectAttribute(m_accountName, "distinguishedName");
    if(m_distinguishedName.contains("OU=")){
        int idx =  m_distinguishedName.indexOf("OU=");
        QString temp = m_distinguishedName.replace(0, idx, "");
        //QString temp = m_distinguishedName.remove("CN=" + m_cn + "," ) ;
        temp = temp.remove("," + ADUser::getADDefaultNamingContext());
        temp = temp.remove("OU=");
        QStringList templist = temp.split(",");
        temp = "";
        while (!templist.isEmpty()) {
            temp = temp + templist.takeLast() + "\\";
        }
        temp = temp.left(temp.size() - 1);
        m_simpleOUString = temp;

        ui.comboBoxOU->setCurrentIndex(ui.comboBoxOU->findText(temp) );
    }

    bool accountDisabled = m_adsi->accountDisabled(m_accountName);;
    m_adUser.setAccountDisabled(accountDisabled);
    ui.checkBoxAccountDisabled->setChecked(accountDisabled);

    bool userMustChangePasword = m_adsi->userMustChangePassword(m_accountName);
    m_adUser.setUserMustChangePassword(userMustChangePasword);
    ui.checkBoxUserMustChangePassword->setChecked(userMustChangePasword);

    bool userCannotChangePassword = m_adsi->userCannotChangePassword(m_accountName);
    //m_adUser.setUserCanChangePassword(userCanChangePassword);
    ui.checkBoxUserCannotChangePassword->setChecked(userCannotChangePassword);

    bool passwordNeverExpires = m_adsi->passwordNeverExpires(m_accountName);
    m_adUser.setPasswordNeverExpires(passwordNeverExpires);
    ui.checkBoxPasswordNeverExpires->setChecked(passwordNeverExpires);


    if(m_distinguishedName.contains(",CN=Users")){
        ui.pushButtonEdit->setEnabled(false);
        ui.pushButtonEdit->setVisible(false);
    }

    m_guid = m_adsi->AD_GetObjectAttribute(m_accountName, "objectGUID");
    m_adUser.setAttribute("objectGUID", m_guid);
    m_sid = m_adsi->AD_GetObjectAttribute(m_accountName, "objectSid");
    m_adUser.setAttribute("objectSid", m_sid);
    ui.lineEditGUID->setText(m_guid);
    ui.lineEditSID->setText(m_sid);


//#ifdef Q_OS_WIN32
//    WindowsManagement wm(this);
//    QString computername = wm.getComputerName().toUpper();
//    QString username = wm.getUserNameOfCurrentThread();

//    if(!m_userWorkstations.contains(computername, Qt::CaseInsensitive)){

//    }

//    QStringList localGroups;
//    wm.getLocalGroupsTheUserBelongs(&localGroups, accountName);
//    QMessageBox::information(this, "localGroups", localGroups.join(","));

//#endif



}

void ADUserInfoWidget::switchToCreatingMode(){

    switchToEditMode();

    ui.lineEditSAMAccount->setReadOnly(false);
    ui.lineEditSAMAccount->setFocus();
    ui.checkBoxUnlockAccount->hide();
    ui.groupBoxID->hide();
    ui.groupBoxUseLocalComputer->hide();

    ui.pushButtonEdit->setText(tr("&Create"));
}

void ADUserInfoWidget::switchToEditMode(){

    ui.lineEditSAMAccount->setReadOnly(true);
    ui.lineEditDisplayName->setReadOnly(false);
    ui.lineEditDisplayName->setFocus();
    ui.lineEditDescription->setReadOnly(false);
    ui.lineEditUserWorkstations->setReadOnly(false);
    ui.lineEditTelephone->setReadOnly(false);
    ui.lineEditDepartment->setReadOnly(false);
    ui.lineEditTitle->setReadOnly(false);
    ui.comboBoxOU->setEnabled(true);
    ui.checkBoxAccountDisabled->setEnabled(true);
    ui.checkBoxUnlockAccount->setEnabled(true);

    ui.framePassword->show();
    ui.lineEditPassword->clear();
    ui.lineEditConfirmPassword->clear();
    ui.checkBoxUserMustChangePassword->setEnabled(true);
    ui.checkBoxUserCannotChangePassword->setEnabled(true);
    ui.checkBoxPasswordNeverExpires->setEnabled(true);


    ui.pushButtonEdit->setText(tr("&Save"));

}

void ADUserInfoWidget::switchToViewMode(){

    ui.lineEditSAMAccount->setReadOnly(true);
    ui.lineEditDisplayName->setReadOnly(true);
    ui.lineEditDescription->setReadOnly(true);
    ui.lineEditUserWorkstations->setReadOnly(true);
    ui.lineEditTelephone->setReadOnly(true);
    ui.lineEditDepartment->setReadOnly(true);
    ui.lineEditTitle->setReadOnly(true);
    ui.comboBoxOU->setEnabled(false);
    ui.checkBoxAccountDisabled->setEnabled(false);
    ui.checkBoxUnlockAccount->setEnabled(false);
    ui.checkBoxUnlockAccount->setChecked(false);

    ui.framePassword->hide();
    ui.lineEditPassword->clear();
    ui.lineEditConfirmPassword->clear();
    ui.checkBoxUserMustChangePassword->setEnabled(false);
    ui.checkBoxUserCannotChangePassword->setEnabled(false);
    ui.checkBoxPasswordNeverExpires->setEnabled(false);

    ui.groupBoxID->show();

    ui.pushButtonEdit->setText(tr("&Edit"));
    ui.pushButtonClose->setFocus();

}











} //namespace HEHUI
