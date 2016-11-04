## Introduction
These examples show how to set various options on the ABL client socket object for use with the HTTP Client.

## USage
The table below shows the mapping from `OpenEdge.Net.ServerConnection.ClientSocket` properties to ABL socket option name passed into the `SET-SOCKET-OPTION()` method.

| Option name | Property name | Http Client usage | Description (from ABL Help) |
| ------- | ------- | ------- |  ------- | 
| TCP-NODELAY | NoDelay | LOGICAL | An enable indicator, which is either TRUE or FALSE.  |
| SO-KEEPALIVE | KeepAlive | LOGICAL | Sets the TCP socket option SO_KEEPALIVE. Set arguments to TRUE to turn this option on or to FALSE to turn it off. |
| SO-REUSEADDR | ReuseAddress |LOGICAL | Sets the TCP socket option SO_REUSEADDR.  Set arguments to TRUE to turn this option on or to FALSE to turn it off. |
| SO-RCVBUF | ReceiveBufferSize | INTEGER | Sets the TCP socket option SO_RCVBUF or SO_SNDBUF. Set arguments to the desired size of the buffer. |
|SO-SNDBUF | SendBufferSize |INTEGER | Sets the TCP socket option SO_RCVBUF or SO_SNDBUF. Set arguments to the desired size of the buffer. Note: Depending on your platform, the value you supply might be increased to the platform's minimum buffer size, decreased to the platform's maximum buffer size, or rounded up to the next multiple of the platform's segment size. For more information, see your platform's documentation. |
| SO-RCVTIMEO | ReceiveTimeout |INTEGER | Sets the timeout length—that is, the number of seconds the socket waits to receive data before timing out. Set arguments to the desired timeout value in seconds. If a timeout occurs, READ( ) returns TRUE and the value of BYTES-READ is zero. This is true whether the READ( ) mode is READ-AVAILABLE or READ-EXACT-NUM. |
 
For more information on the interaction of READ( ), the READ( ) mode, and SO_RCVTIMEO, see OpenEdge Development: Programming Interfaces.
