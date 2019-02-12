# financial-statements
Developed by the [UC San Diego Department of Medicine](http://med.ucsd.edu) for building the back-end (SQL Server tables and stored procedures) necessary for custom reporting and detailed analyses.  This code replicates, with custom modifications for Medicine purposes, [querylink.ucsd.edu](http://querylink.ucsd.edu).

## Getting Started

### Prerequisites
* Authorization and connection to Medicine SQL Server required.
* [GA](https://github.com/UCSDMed/dw_db-ga) schema setup and updated.
* [QLINK_DB](https://github.com/UCSDMed/dw_db-qlink_db) schema setup and updated.
* [COA_DB](https://github.com/UCSDMed/dw_db-coa_db) schema setup and updated.
* Cognos schema setup and updated.
* Specified error handling procedures on SQL Server preferred.

### Installing

### Modules
#### [ql_operating_ledger.sql](/blob/master/ql_operating_ledger.sql)
* Operating Ledger Detail Activity used for P&L and other reporting at the transaction level.
* @selectFullAccountingPeriod: Fiscal (July - June) accounting period as YYYYMM integer
* @pullDataPeriods: 'MTD' (Month-to-Date), 'FYTD' (Fiscal Year-to-Date; default), '12MTD' (12 Month-to-Date), else (All Transactions)

## Built With
* [SSMS](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) - SQL Environment
* [VS Code](https://code.visualstudio.com/) - Integrated Development Environment

## Author(s)
* **Matthew C. Vanderbilt** - *Initial work* - [rdy2dve](https://github.com/rdy2dve)

## License
This code is licensed under GNU General Public License Version 3 - see teh [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments
