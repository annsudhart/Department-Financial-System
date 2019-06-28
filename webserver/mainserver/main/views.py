from django.shortcuts import render

from . import scripts

def normalize(request):
    """ 
    Handles requests and displayment of /normalize.html.

    Parameters
    ----------
    request: HttpRequest
    Can be POST or GET requests to ./normalize.html. If POST, whatever
        name was passed into the POST string will be converted 
        to last name, first name format. 
    
    Returns
    ----------
    HttpResponse
        The main/normalize.html web page allowing normlization use
    """
    if request.method == 'POST':
        name = request.POST['name']
        context = {'result': scripts.normalize(name)}
    else:
        context = {'result': 'Not normalizing anything'}
    print('returning normalize webpage...')
    return render(request, 'main/normalize.html', context)

def index(request):
    """ 
    Handles requests and displayment of /index.html.

    Parameters
    ----------
    request: HttpRequest
        A GET request to ./index.html.
    
    Returns
    ----------
    HttpResponse
        The main/index.html web page
    """
    return render(request, 'main/index.html')

def connect(request):
    """ 
    Handles requests and displayment of /context.html.

    Parameters
    ----------
    request: HttpRequest
        A GET request to ./connect.html, which displays your connection
        status to the bso_dev SQL Server.

    Returns
    ----------
    HttpResponse
        The main/connect.html web page displaying database connection status
    """
    context = {'text': "You aren't connected to the database. Try enabling " 
                       "your VPN and then refreshing your browser."}
    try:
        conn = scripts.connect()
        print(conn)
        context['text'] = 'You are connected!'
    except:
        context['text'] = "You aren't connected to the database. Try enabling your VPN and then refreshing your browser."
    return render(request, 'main/connect.html', context)