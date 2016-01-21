/*
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Please refer to the README for information about making permanent changes.  #
################################################################################
*/

#include "QmlZiflist.h"


///
//  Reload network interfaces from system
void QmlZiflist::reload () {
    ziflist_reload (self);
};

///
//  Return the number of network interfaces on system
size_t QmlZiflist::size () {
    return ziflist_size (self);
};

///
//  Get first network interface, return NULL if there are none
const QString QmlZiflist::first () {
    return QString (ziflist_first (self));
};

///
//  Get next network interface, return NULL if we hit the last one
const QString QmlZiflist::next () {
    return QString (ziflist_next (self));
};

///
//  Return the current interface IP address as a printable string
const QString QmlZiflist::address () {
    return QString (ziflist_address (self));
};

///
//  Return the current interface broadcast address as a printable string
const QString QmlZiflist::broadcast () {
    return QString (ziflist_broadcast (self));
};

///
//  Return the current interface network mask as a printable string
const QString QmlZiflist::netmask () {
    return QString (ziflist_netmask (self));
};

///
//  Return the list of interfaces.
void QmlZiflist::print () {
    ziflist_print (self);
};


QObject* QmlZiflist::qmlAttachedProperties(QObject* object) {
    return new QmlZiflistAttached(object);
}


///
//  Self test of this class.
void QmlZiflistAttached::test (bool verbose) {
    ziflist_test (verbose);
};

///
//  Get a list of network interfaces currently defined on the system
QmlZiflist *QmlZiflistAttached::construct () {
    QmlZiflist *qmlSelf = new QmlZiflist ();
    qmlSelf->self = ziflist_new ();
    return qmlSelf;
};

///
//  Destroy a ziflist instance
void QmlZiflistAttached::destruct (QmlZiflist *qmlSelf) {
    ziflist_destroy (&qmlSelf->self);
};

/*
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Please refer to the README for information about making permanent changes.  #
################################################################################
*/
