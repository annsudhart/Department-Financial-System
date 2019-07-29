from django.shortcuts import render

from . import scripts

not_connected_msg = "You are not connected to the database. " \
                    "Try enabling your VPN and then refreshing your browser."
connected_msg = "You are connected!"
index_url = "main/index.html"
connect_url = "main/connect.html"

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
    default_formval =  '--------'
    form_input_prefix = 'input'
    default_width = 8
    default_height = 100

    width = default_width
    height = default_height

    # info to be passed as part of the HTTP request
    context = { 'range': range(1, width), 
                'rows': range(height), 
                'display' : False }

    # a list of tuples containing the value name 
    # and their corresponding name from the form input
    formvals = []
    if request.method == 'POST':
        # gather form input
        for i in range(1, 8):
            # val: a tuple with valuename and value to be added onto formvals
            val = (i, request.POST[form_input_prefix + str(i)])
            if val[1] == '':
                val = (i, default_formval)
            formvals.append(val)
        context['display'] = True
        # TODO: gather form output
        conn = scripts.connect()
        cursor = scripts.view(conn)
        tableoutput = []
        while True:
            row = cursor.fetchone()
            # versionnumber, which is of type bytes
            if not row:
                break
            row.versionnumber = row.versionnumber.hex()
            tableoutput.append(row) 
        context['outputname'] = cursor.description
        context['output'] = tableoutput
    context['values'] = formvals
    if request.method == 'POST':
        return render(request, index_url, context)
    return render(request, index_url, context)

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
    context = {'text': not_connected_msg}
    try:
        conn = scripts.connect()
        print(conn)
        context['text'] = connected_msg
    except:
        context['text'] = not_connected_msg
    return render(request, connect_url, context)