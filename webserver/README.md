# UCSD SQL web server
This is a web server that interfaces the UCSD School of Medicine 
Financial Department's SQL Server. 

## Setup 
1. Installing 
* [Python 3.7 and related packages](https://www.anaconda.com/distribution/)
* [Microsoft Visual C++ 14.0](https://visualstudio.microsoft.com/downloads/)
* [Microsoft ODBC Driver 17 for SQL Server 17.3.1.1](https://www.microsoft.com/en-us/download/confirmation.aspx?id=56567&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1)
* Django 2.2 with the terminal command `pip install django`
* In addition, install anything imported through fuzzymatch.py

2. Install mod_wsgi to connect web application to Apache  
Make a copy of the Apache24 folder and put it under the C:/ folder.
Then run the following script in your terminal: `pip install mod_wsgi`.
3. Modify paths in code for Apache configuration
In line 37, which looks like the following:
`Define SRVROOT "c:/users/ahsudharta/documents/web-server/Apache24"`
And in lines 543 - 549:
~~~
LoadFile 'C:/users/ahsudharta/appdata/local/continuum/anaconda3/python37.dll'
LoadModule wsgi_module 'C:/users/ahsudharta/appdata/local/continuum/anaconda3/lib/site-packages/mod_wsgi-4.6.5-py3.7-win-amd64.egg/mod_wsgi/server/mod_wsgi.cp37-win_amd64.pyd'
WSGIScriptAlias / 'C:/users/ahsudharta/documents/web-server/mainserver/mainserver/wsgi.py'
WSGIPythonHome "C:/Users/ahsudharta/AppData/Local/Continuum/anaconda3"
WSGIPythonPath 'C:/users/ahsudharta/documents/web-server/mainserver'

<Directory "/Users/ahsudharta/Documents/web-server/mainserver/mainserver">
~~~
Replace the following lines of code with the proper file pathways, and that it matches up with the output of the terminal script `mod_wsgi-express module-config`.
4. Run the server!
On the command line terminal go to the directory where web-server is and then run `./Apache24/bin/httpd.exe`. Then go to your web browser and type in localhost/main.

## Current Status
Working on displaying to user if they are connected to the database or not before running SQL code

## Development Status
Created part of the main page as per the interface design. Just waiting on more details
that I can work on.
