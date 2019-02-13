USE dw_db;
GO

DROP TABLE IF EXISTS ap.check_item;

/****** Object:  Table [ap].[check_item]    Script Date: 07/12/2018 2:41:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE ap.check_item
	(
	bank_code						char(2)							NOT	NULL,
	check_number					char(8)							NOT	NULL,
	document_number					char(8)							NOT	NULL,
	item_number						int								NOT	NULL,
	sequence_number					int								NOT	NULL,
	full_accounting_period			int									NULL,
	account_index					varchar(10)							NULL,
	fund							varchar(6)							NULL,
	organization					varchar(6)							NULL,
	account							varchar(6)							NULL,
	program							varchar(6)							NULL,
	[location]						varchar(6)							NULL,
	approved_amount					numeric(19, 4)						NULL,
	discount_amount					numeric(19, 4)						NULL,
	tax_amount						numeric(19, 4)						NULL,
	additional_charge_amount		numeric(19, 4)						NULL,
	paid_amount						numeric(19, 4)						NULL,
	federal_withheld_amount			numeric(19, 4)						NULL,
	state_withheld_amount			numeric(19, 4)						NULL,
	check_rule_class				varchar(4)							NULL,
	discount_rule_class				varchar(4)							NULL,
	tax_rule_class					varchar(4)							NULL,
	additional_charge_rule_class	varchar(4)							NULL,
	po_number						varchar(8)							NULL,
	po_item_number					smallint							NULL,
	liquidation_ind					char(1)								NULL,
	doc_type_sequence_number		smallint							NULL,
	adjustment_code					varchar(2)							NULL,
	vendor_invoice_number			varchar(9)							NULL,
	vendor_invoice_date				varchar(8)							NULL,
	document_reference_number		varchar(10)							NULL,
	tax_rate_code					varchar(3)							NULL,
	refresh_date					datetime2(7)					NOT	NULL,
	ind_592							char(1)								NULL,
	state_withheld_592_amt			numeric(19, 4)						NULL,
	ftb_chk_rpt_amt					numeric(19, 4)						NULL,
    rowguid                         UNIQUEIDENTIFIER ROWGUIDCOL         NULL DEFAULT NEWSEQUENTIALID(),
    version_number                  ROWVERSION
	)
    CREATE INDEX CHECK_ITEM_INDEX2	ON	ap.check_item(account_index)
    CREATE INDEX CHECK_ITEM_INDEX3	ON	ap.check_item(document_reference_number)
    CREATE INDEX CHECK_ITEM_INDEX4	ON	ap.check_item(po_number, po_item_number)
    CREATE INDEX CHECK_ITEM_INDEX6	ON	ap.check_item(full_accounting_period, check_number)
	CREATE INDEX CHECK_ITEM_INDEX7	ON	ap.check_item(vendor_invoice_number)
	CREATE INDEX CHECK_ITEM_PK		ON	ap.check_item(check_number, document_number, item_number, sequence_number, bank_code)
	CREATE INDEX I_CI_FUND_INDX		ON	ap.check_item(fund)
GO


