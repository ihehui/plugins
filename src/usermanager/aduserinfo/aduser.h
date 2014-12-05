#ifndef ADUSER_H
#define ADUSER_H

#include <QHash>
#include <QStringList>



namespace HEHUI {


class ADUser
{

public:
    explicit ADUser();

    static QString CommonAttributeName(const QString &attributeName);

    static void setOUList(const QStringList &ouList);
    static QStringList getOUList();

    static void setADDefaultNamingContext(const QString &adDefaultNamingContext);
    static QString getADDefaultNamingContext();


    void setAttribute(const QString &attributeName, const QString &attributeValue);
    QString getAttribute(const QString &attributeName);

    bool accountDisabled();
    void setAccountDisabled(bool disabled);

//    bool accountLocked();
//    void setAccountLocked(bool locked);

    bool userMustChangePassword();
    void setUserMustChangePassword(bool userMustChangePassword);

//    bool userCanChangePassword();
    void setUserCanChangePassword(bool userCanChangePassword);

    bool passwordNeverExpires();
    void setPasswordNeverExpires(bool passwordNeverExpires);


private:
    static QHash<QString/*AD Attribute Name*/, QString/*Common Attribute Name*/> *commonAttributeNameHash;
    static QStringList m_ouList;
    static QString m_ADDefaultNamingContext;

    QHash<QString/*AD Attribute Name*/, QString/*Attribute Value*/> attributeHash;
    
    bool m_isAccountDisabled;
//    bool m_isAccountLocked;
    bool m_userMustChangePassword;
    bool m_userCanChangePassword;
    bool m_passwordNeverExpires;

};

} //namespace HEHUI

#endif // ADUSER_H
