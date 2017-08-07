/*------------------------------------------------------------------------
    File        : session_start.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu May 19 12:32:51 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Web.DataObject.ServiceRegistry.

define input  parameter pcArgs as character no-undo.

/* ***************************  Main Block  *************************** */
// registers callbackhandlers for the DOh
new DOHEventHandler().
