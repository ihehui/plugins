
#include <QObject>
#include <QDebug>


#include "aduser.h"


namespace HEHUI
{


QHash<QString/*AD Attribute Name*/, QString/*Common Attribute Name*/> *ADUser::commonAttributeNameHash = 0;
QStringList ADUser::m_ouList = QStringList();
QString ADUser::m_ADDefaultNamingContext = "";


ADUser::ADUser()
{

    if(!commonAttributeNameHash) {
        commonAttributeNameHash = new QHash<QString, QString>();
        commonAttributeNameHash->insert("accountExpires", QObject::tr("Account Expires"));
        commonAttributeNameHash->insert("badPasswordTime", QObject::tr("Bad Password Time"));
        commonAttributeNameHash->insert("badPwdCount", QObject::tr("Bad Password Count"));
        commonAttributeNameHash->insert("cn", QObject::tr("Common Name"));
        commonAttributeNameHash->insert("codePage", QObject::tr("Code Page"));
        commonAttributeNameHash->insert("countryCode", QObject::tr("Country Code"));
        commonAttributeNameHash->insert("description", QObject::tr("Description"));
        commonAttributeNameHash->insert("department", QObject::tr("Department"));
        commonAttributeNameHash->insert("displayName", QObject::tr("Display Name"));
        commonAttributeNameHash->insert("distinguishedName", QObject::tr("Distinguished Name"));
        commonAttributeNameHash->insert("dSCorePropagationData", QObject::tr("Core Propagation Data"));
        commonAttributeNameHash->insert("homeDirectory", QObject::tr("Home Directory"));
        commonAttributeNameHash->insert("homeDrive", QObject::tr("Home Drive"));
        commonAttributeNameHash->insert("instanceType", QObject::tr("Instance Type"));
        commonAttributeNameHash->insert("lastLogoff", QObject::tr("Last Logoff"));
        commonAttributeNameHash->insert("lastLogon", QObject::tr("Last Logon"));
        commonAttributeNameHash->insert("logonCount", QObject::tr("Logon Count"));
        commonAttributeNameHash->insert("lockoutTime", QObject::tr("Lockout Time"));
        commonAttributeNameHash->insert("mail", QObject::tr("E-mail"));
        commonAttributeNameHash->insert("memberOf", QObject::tr("Member Of"));
        commonAttributeNameHash->insert("name", QObject::tr("Name"));
        commonAttributeNameHash->insert("nTSecurityDescriptor", QObject::tr("NT Security Descriptor"));
        commonAttributeNameHash->insert("objectCategory", QObject::tr("Object Category"));
        commonAttributeNameHash->insert("objectClass", QObject::tr("Object Class"));
        commonAttributeNameHash->insert("objectGUID", QObject::tr("Object GUID"));
        commonAttributeNameHash->insert("objectSid", QObject::tr("Object SID"));
        commonAttributeNameHash->insert("primaryGroupID", QObject::tr("Primary Group ID"));
        commonAttributeNameHash->insert("pwdLastSet", QObject::tr("Password Last Set"));
        commonAttributeNameHash->insert("sAMAccountName", QObject::tr("SAM Account Name"));
        commonAttributeNameHash->insert("sAMAccountType", QObject::tr("SAM Account Type"));
        commonAttributeNameHash->insert("telephoneNumber", QObject::tr("Telephone Number"));
        commonAttributeNameHash->insert("title", QObject::tr("Title"));
        commonAttributeNameHash->insert("userAccountControl", QObject::tr("User Account Control"));
        commonAttributeNameHash->insert("userPrincipalName", QObject::tr("User Principal Name"));
        commonAttributeNameHash->insert("userWorkstations", QObject::tr("User Workstations"));
        commonAttributeNameHash->insert("uSNChanged", QObject::tr("USN Changed"));
        commonAttributeNameHash->insert("uSNCreated", QObject::tr("USN Created"));
        commonAttributeNameHash->insert("whenChanged", QObject::tr("When Changed"));
        commonAttributeNameHash->insert("whenCreated", QObject::tr("When Created"));


    }

    m_isAccountDisabled = false;
//    m_isAccountLocked = false;
    m_userMustChangePassword = true;
    m_userCanChangePassword = true;
    m_passwordNeverExpires = false;


}

void ADUser::setAttribute(const QString &attributeName, const QString &attributeValue)
{
    attributeHash.insert(attributeName, attributeValue);
}

QString ADUser::getAttribute(const QString &attributeName)
{
    return attributeHash.value(attributeName);
}

bool ADUser::accountDisabled()
{
    return m_isAccountDisabled;
}

void ADUser::setAccountDisabled(bool disabled)
{
    m_isAccountDisabled = disabled;
}

//bool ADUser::accountLocked(){
//    return m_isAccountLocked;
//}

//void ADUser::setAccountLocked(bool locked){
//    m_isAccountLocked = locked;
//}

bool ADUser::userMustChangePassword()
{
    return m_userMustChangePassword;
}

void ADUser::setUserMustChangePassword(bool userMustChangePassword)
{
    m_userMustChangePassword = userMustChangePassword;
}

//bool ADUser::userCanChangePassword(){
//    return m_userCanChangePassword;
//}

void ADUser::setUserCanChangePassword(bool userCanChangePassword)
{
    m_userCanChangePassword = userCanChangePassword;
}

bool ADUser::passwordNeverExpires()
{
    return m_passwordNeverExpires;
//    unsigned long ADS_UF_DONT_EXPIRE_PASSWD = 0x10000;
//    unsigned long userAccountControl = attributeHash.value("userAccountControl").toULong();
//    qDebug()<<"---------------userAccountControl:"<<userAccountControl;
//    qDebug()<<"---------------userAccountControl^UF_DONT_EXPIRE_PASSWD:"<<QString::number(userAccountControl^ADS_UF_DONT_EXPIRE_PASSWD);
//    qDebug()<<"---------------userAccountControl|UF_DONT_EXPIRE_PASSWD:"<<QString::number(userAccountControl|ADS_UF_DONT_EXPIRE_PASSWD);
//    qDebug()<<"---------------userAccountControl&UF_DONT_EXPIRE_PASSWD:"<<QString::number(userAccountControl&ADS_UF_DONT_EXPIRE_PASSWD);

    //return userAccountControl == (userAccountControl|ADS_UF_DONT_EXPIRE_PASSWD);
//    return userAccountControl&ADS_UF_DONT_EXPIRE_PASSWD;

}

void ADUser::setPasswordNeverExpires(bool passwordNeverExpires)
{
    m_passwordNeverExpires = passwordNeverExpires;
}

QString ADUser::CommonAttributeName(const QString &attributeName)
{
    QString name = commonAttributeNameHash->value(attributeName);
    if(name.isEmpty()) {
        name = attributeName;
    }

    return name;
}

void ADUser::setOUList(const QStringList &ouList)
{
    m_ouList = ouList;
}

QStringList ADUser::getOUList()
{
    return m_ouList;
}

void ADUser::setADDefaultNamingContext(const QString &adDefaultNamingContext)
{
    m_ADDefaultNamingContext = adDefaultNamingContext;
}

QString ADUser::getADDefaultNamingContext()
{
    return m_ADDefaultNamingContext;
}







} //namespace HEHUI
