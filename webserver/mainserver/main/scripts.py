from fuzzywuzzy.fuzz import partial_ratio
import re
import numpy as np
import string
from nameparser import HumanName
import pyodbc as db
import json
import os

def get_connect_info():
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sensitive.json')) as basefile:
        jsonfile = json.load(basefile)
        sql_connector = jsonfile['sql_connector']
        return sql_connector

threshold = 60

# normalizes the name for typos
def normalize(s):
    s = re.sub('\s+', ' ', s)
    s = str(HumanName(s))
    symbols = [char for char in string.punctuation if char not in [',', '.', '-']] + [str(n) for n in range(10)]
    for p in symbols:
        s = s.replace(p, '')
    return str(s).upper()

# returns the first and last names of the string s
def first_last(s):
    s = re.sub('\s+', ' ', str(s))
    symbols = [char for char in string.punctuation if char not in [',', '.', '-']] + [str(n) for n in range(10)]
    for p in symbols:
        s = s.replace(p, '')
    name = HumanName(s)
    return "%s %s" % (name.first.upper(), name.last.upper())

def connect():
    """
    
    Connects to the MSSQL Database. If you're not connected via VPN,
    the function will take around 20 seconds to complete.

    Returns
    ----------
    conn: The instance of the database.

    """
    conn = db.connect(get_connect_info())
    return conn

def update_bks_matched():
    cursor = conn.cursor()
    cursor.execute("USE [bso_dev]")
    cursor.execute("CREATE TABLE pur.temp_table (employee_id INT, employee_name VARCHAR(35))")
    for index,row in bks.iterrows():
        if(np.isnan(bks["employee_id"][index])):
            cursor.execute("INSERT INTO pur.temp_table values (?, ?)", (None, bks["employee_name"][index]))
        else:
            cursor.execute("INSERT INTO pur.temp_table values (?, ?)", (int(bks["employee_id"][index]), bks["employee_name"][index]))
    try:
        cursor.execute("DROP TABLE pur.bks_matched")
    except:
        ...
    cursor.execute("SELECT * INTO pur.bks_matched FROM pur.bks_purchase")
    update_query = """
    UPDATE pur.bks_matched

    SET pur.bks_matched.employee_id = pur.temp_table.employee_id

    FROM pur.bks_matched INNER JOIN pur.temp_table ON pur.bks_matched.employee_name = pur.temp_table.employee_name
    """
    cursor.execute(update_query)
    cursor.execute("DROP TABLE pur.temp_table")
    conn.commit()
    cursor.close()

def view(conn):
    cursor = conn.cursor()
    return cursor.execute( """SELECT TOP (100) 
        [bks_transaction_id],
        [modification_indicator],      
        [transaction_date],      
        [purchase_invoice_number], 
        [discount_amount],      
        [freight_amount],      
        [duty_amount],      
        [order_date],      
        [transaction_amount],      
        [use_tax_flag], 
        [use_tax_amount],      
        [employee_id],      
        [employee_name],      
        [document_number],      
        [comment],      
        [createdby],      
        [createddate],      
        [lastupdatedby],      
        [lastupdated],      
        [rowguid],      
        [versionnumber],      
        [validfrom],      
        [validto]
        FROM [bso_dev].[pur].[bks_purchase]""" )