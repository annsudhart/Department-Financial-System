from django.shortcuts import render

from . import scripts

def normalize(request):
    """ Handles requests and displayment of /normalize.html.

    Parameters
    ----------
    request: Can be POST or GET requests to ./normalize.html. If POST, whatever
        name was passed into the POST string will be converted 
        to last name, first name format. 

    """
    if request.method == 'POST':
        name = request.POST['name']
        context = {'result': scripts.normalize(name)}
    else:
        context = {'result': 'Not normalizing anything'}
    print('returning normalize webpage...')
    return render(request, 'main/normalize.html', context)

def index(request):
    """ Handles requests and displayment of /index.html.

    Parameters
    ----------
    request: A GET request to ./index.html.

    """
    return render(request, 'main/index.html')

def runsql(request):
    """ Handles requests and displayment of /result.html.

    Parameters
    ----------
    request: Can be POST or GET requests to ./normalize.html. If POST, whatever
        name was passed into the POST string will be converted 
        to last name, first name format. 

    """
    context = {'success': False, 'text': ''}
    if request.method == 'POST':
        try:
            conn = scripts.connect()
        except:
            print('A timeout occurred...')
        context['success'] = True
        context['text'] = request.POST['sqlcode']
        print('connecting to bso_dev database...')
        cursor = conn.cursor()
        cursor.execute("USE [bso_dev]")
        print('running code...')
        # Executes T-SQL code
        # TODO add input processing so any script passed into the request param
        #      is safely runnable by this program.
        cursor.execute('''SELECT TOP (10) [bks_transaction_id]
            ,[modification_indicator]
            ,[transaction_date]
            ,[purchase_invoice_number]
            ,[discount_amount]
            ,[freight_amount]
            ,[duty_amount]
            ,[order_date]
            ,[transaction_amount]
            ,[use_tax_flag]
            ,[use_tax_amount]
            ,[employee_id]
            ,[employee_name]
            ,[document_number]
            ,[comment]
            ,[createdby]
            ,[createddate]
            ,[lastupdatedby]
            ,[lastupdated]
            ,[rowguid]
            ,[versionnumber]
            ,[validfrom]
            ,[validto]
            FROM [bso_dev].[pur].[bks_purchase]''')
        result = ''
        rows = cursor.fetchall()[:10]
        print(rows[0])
        context['text'] = result
        print('closing connection...')
    return render(request, 'main/result.html', context)