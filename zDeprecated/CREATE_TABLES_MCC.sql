/***************************************************************************************
Name      : BSO Financial Management Interface - MCC Codes
License   : Copyright (C) 2018 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates Merchant Category Code tables - does not create import/update procedures
- Based on http://resourcecenter.americanexpress.com/~/media/ResourceCenter/US/Docs/Reconciliation%20and%20Reports/Merchant%20Category%20Codes.ashx
****************************************************************************************
PREREQUISITES:
- none
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE [dw_db];
GO

/*  Specify ISO compliant behavior of the Equals (=) and Not Equal To (<>) comparison
    operators when they are used with null values.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-ansi-nulls-transact-sql
    -   When SET ANSI_NULLS is ON, a SELECT statement that uses WHERE column_name = NULL 
        returns zero rows even if there are null values in column_name. A SELECT 
        statement that uses WHERE column_name <> NULL returns zero rows even if there 
        are nonnull values in column_name. 
    -   When SET ANSI_NULLS is OFF, the Equals (=) and Not Equal To (<>) comparison 
        operators do not follow the ISO standard. A SELECT statement that uses WHERE 
        column_name = NULL returns the rows that have null values in column_name. A 
        SELECT statement that uses WHERE column_name <> NULL returns the rows that 
        have nonnull values in the column. Also, a SELECT statement that uses WHERE 
        column_name <> XYZ_value returns all rows that are not XYZ_value and that are 
        not NULL. */
SET ANSI_NULLS ON;
GO

/*  Causes SQL Server to follow  ISO rules regarding quotation mark identifiers &
    literal strings.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql
    -   When SET QUOTED_IDENTIFIER is ON, identifiers can be delimited by double 
        quotation marks, and literals must be delimited by single quotation marks. When 
        SET QUOTED_IDENTIFIER is OFF, identifiers cannot be quoted and must follow all 
        Transact-SQL rules for identifiers. */
SET QUOTED_IDENTIFIER ON;
GO

PRINT '-- Delete Existing Objects';
GO

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @schemaName NVARCHAR(128) = '';
DECLARE @objectName NVARCHAR(128) = '';
DECLARE @objectType NVARCHAR(1) = '';
DECLARE @localCounter INTEGER = 0;
DECLARE @loopMe BIT = 1;

WHILE @loopMe = 1
BEGIN

    SET @schemaName = 'dbo'
    SET @localCounter = @localCounter + 1

    IF @localCounter = 1
    BEGIN
        SET @objectName = 'mcc_code'
        SET @objectType = 'U'
    END
    ELSE IF @localCounter = 2
    BEGIN
        SET @objectName = 'mcc_group'
        SET @objectType = 'U'
    END
    ELSE SET @loopMe = 0

    IF @objectType = 'U' SET @SQL = 'TABLE'
    ELSE IF @objectType = 'P' SET @SQL = 'PROCEDURE'
    ELSE IF @objectType = 'V' SET @SQL = 'VIEW'
    ELSE SET @loopMe = 0

    SET @SQL = 'DROP ' + @SQL + ' ' + @schemaName + '.' + @objectName

    IF @loopMe = 1 AND OBJECT_ID(@schemaName + '.' + @objectName,@objectType) IS NOT NULL
    BEGIN
        BEGIN TRY
            PRINT @SQL
            EXEC(@SQL)
        END TRY
        BEGIN CATCH
            EXEC dbo.PrintError
            EXEC dbo.LogError
        END CATCH
    END

END

PRINT '-- dbo.mcc_group'
BEGIN TRY
    CREATE TABLE dbo.mcc_group
    (
        mcc_group                   INTEGER							NOT	NULL,
		mcc_group_description		NVARCHAR(35)						NULL,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_dbo_mccgroup PRIMARY KEY (mcc_group)
    )

	INSERT INTO dbo.mcc_group
		(
			mcc_group,
			mcc_group_description
		)
		VALUES
			(0, 'Unidentified'),
			(1, 'Airlines'),
			(2, 'Amusement & Entertainment'),
			(3, 'Association'),
			(4, 'Auto Rental'),
			(5, 'Automobiles & Vehicles'),
			(6, 'Business Services'),
			(7, 'Cleaning Preparations'),
			(8, 'Clothing Stores'),
			(9, 'Contracted Services'),
			(10, 'Education'),
			(11, 'Gas Stations'),
			(12, 'Government Services'),
			(13, 'Hotels & Motels'),
			(14, 'Mail Phone Order'),
			(15, 'Miscellaneous Stores'),
			(16, 'Personal Services'),
			(17, 'Professional Services'),
			(18, 'High Risk Personal Retail'),
			(19, 'High Risk Personal Services'),
			(20, 'Publishing Services'),
			(21, 'Repair Services'),
			(22, 'Restaurants'),
			(23, 'Retail Stores'),
			(24, 'Service Providers'),
			(25, 'Telecom & Data Utilities'),
			(26, 'Transportation'),
			(27, 'Utilities'),
			(28, 'Wholesale Trade')

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH

PRINT '-- dbo.mcc_code'
BEGIN TRY
    CREATE TABLE dbo.mcc_code
    (
        mcc_code                    VARCHAR(4)							NOT	NULL,
		mcc_code_description		NVARCHAR(155)						NULL,
		mcc_group					INTEGER							NOT NULL	DEFAULT	0,
        rowguid                     UNIQUEIDENTIFIER ROWGUIDCOL		NOT	NULL	DEFAULT	NEWSEQUENTIALID(),
        version_number              ROWVERSION
		CONSTRAINT PK_dbo_mcccode PRIMARY KEY (mcc_code)
    )

	INSERT INTO dbo.mcc_code
		(
			mcc_group,
			mcc_code,
			mcc_code_description
		)
		VALUES
			(1,4511,'Airlines and Air Carriers'),
			(2,4411,'Steamship and Cruise Lines'),
			(2,7012,'Timeshares'),
			(2,7032,'Sporting and Recreational Camps'),
			(2,7033,'Trailer Parks and Campgrounds'),
			(2,7829,'Motion Picture, and Video Tape Production and Distribution'),
			(2,7832,'Motion Picture Theaters'),
			(2,7841,'Video Tape Rental Stores'),
			(2,7911,'Dance Halls, Studios, and Schools'),
			(2,7922,'Theatrical Producers (except Motion Pictures), and Ticket Agencies'),
			(2,7929,'Bands, Orchestras, and Miscellaneous Entertainers - Not Elsewhere Classified'),
			(2,7932,'Billiard and Pool Establishments'),
			(2,7933,'Bowling Alleys'),
			(2,7941,'Commercial Sports, Professional Sports Clubs, Athletic Fields, and Sports Promoters'),
			(2,7991,'Tourist Attractions and Exhibits'),
			(2,7992,'Public Golf Courses'),
			(2,7993,'Video Amusement Game Supplies'),
			(2,7994,'Video Game Arcades and Establishments'),
			(2,7996,'Amusement Parks, Circuses, Carnivals, and Fortune Tellers'),
			(2,7997,'Membership Clubs (Sports, Recreation, Athletic), Country Clubs, and Private Golf Courses'),
			(2,7998,'Aquariums, Seaquariums, and Dolphinariums'),
			(2,7999,'Recreation Services - Not Elsewhere Classified'),
			(3,8398,'Charitable and Social Service Organizations'),
			(3,8641,'Civic, Social, and Fraternal Associations'),
			(3,8651,'Political Organizations'),
			(3,8661,'Religious Organizations'),
			(3,8675,'Automobile Associations'),
			(3,8699,'Membership Organizations - Not Elsewhere Classified'),
			(4,7512,'Automobile Rental Agency'),
			(5,5013,'Motor Vehicle Supplies and New Parts'),
			(5,5511,'Car and Truck Dealers (New and Used) - Sales, Service, Repairs, Parts, and Leasing'),
			(5,5521,'Car and Truck Dealers (Used Only) - Sales, Service, Repairs, Parts, and Leasing'),
			(5,5531,'Auto and Home Supply Stores'),
			(5,5532,'Automotive Tire Stores'),
			(5,5533,'Auto Parts and Accessories Stores'),
			(5,5551,'Boat Dealers'),
			(5,5561,'Camper, Recreational, and Utility Trailer Dealers'),
			(5,5571,'Motorcycle Shops and Dealers'),
			(5,5592,'Motor Home Dealers'),
			(5,5599,'Miscellaneous Automotive, Aircraft, and Farm Equipment Dealers - Not Elsewhere Classified'),
			(6,7311,'Advertising Services'),
			(6,7321,'Consumer Credit Reporting Agencies'),
			(6,7322,'Debt Collection Agencies'),
			(6,7333,'Commercial Photography, Art, and Graphics'),
			(6,7338,'Quick Copy, Reproduction, and Blueprinting Services'),
			(6,7339,'Stenographic and Secretarial Support Services'),
			(6,7342,'Exterminating and Disinfecting Services'),
			(6,7349,'Cleaning, Maintenance, and Janitorial Services'),
			(6,7361,'Employment Agencies, and Temporary Help Services'),
			(6,7372,'Computer Programming, Data Processing, and Integrated Systems Design Services'),
			(6,7375,'Information Retrieval Services'),
			(6,7379,'Computer Maintenance and Repair Services – Not Elsewhere Classified'),
			(6,7392,'Management, Consulting, and Public Relations Services'),
			(6,7393,'Detective Agencies, Protective Agencies, Security Services (including Armored Cars and Guard Dogs)'),
			(6,7394,'Equipment, Tool, Furniture, and Appliance Rental and Leasing'),
			(6,7395,'Photo Finishing Laboratories, and Photo Developing'),
			(6,7399,'Business Services – Not Elsewhere Classified'),
			(6,7513,'Truck and Utility Trailer Rentals'),
			(6,7519,'Motor Home and Recreational Vehicle Rentals'),
			(7,2842,'Specialty Cleaning, Polishing, and Sanitation Preparations'),
			(8,5611,'Men’s and Boy’s Clothing and Accessory Stores'),
			(8,5631,'Women’s Accessory and Specialty Stores'),
			(8,5641,'Children’s and Infant’s Wear Stores'),
			(8,5651,'Family Clothing Stores'),
			(8,5655,'Sports and Riding Apparel Stores'),
			(8,5691,'Men’s and Women’s Clothing Stores'),
			(8,5697,'Tailors, Seamstresses, Mending, and Alterations'),
			(8,5699,'Miscellaneous Apparel and Accessory Stores'),
			(9,0742,'Veterinary Services'),
			(9,0763,'Agricultural Co-Operatives'),
			(9,0780,'Landscaping and Horticultural Services'),
			(9,1520,'General Contractors - Residential and Commercial'),
			(9,1711,'Heating, Plumbing, and Air Conditioning Contractors'),
			(9,1731,'Electrical Contractors'),
			(9,1740,'Masonry, Stonework, Tile-Setting, Plastering, and Insulation Contractors'),
			(9,1750,'Carpentry Contractors'),
			(9,1761,'Roofing, Siding, and Sheet Metal Work Contractors'),
			(9,1771,'Concrete Work Contractors'),
			(9,1799,'Special Trade Contractors - Not Elsewhere Classified'),
			(10,8211,'Elementary and Secondary Schools'),
			(10,8220,'Colleges, Universities, Professional Schools, and Junior Colleges'),
			(10,8241,'Correspondence Schools'),
			(10,8244,'Business and Secretarial Schools'),
			(10,8249,'Trade and Vocational Schools'),
			(10,8299,'Schools and Educational Services - Not Elsewhere Classified'),
			(11,5541,'Service Stations (with or without Ancillary Services)'),
			(11,5542,'Automated Fuel Dispensers'),
			(12,9211,'Court Costs (including Alimony and Child Support)'),
			(12,9222,'Fines'),
			(12,9311,'Tax Payments'),
			(12,9399,'Government Services - Not Elsewhere Classified'),
			(12,9402,'Postal Services (Government Only)'),
			(13,7011,'Lodging Hotels, Motels, and Resorts'),
			(14,5960,'Direct Marketing - Insurance Services'),
			(14,5962,'Telemarketing - Travel-Related Arrangement Services'),
			(14,5963,'Door-To-Door Sales'),
			(14,5964,'Direct Marketing - Catalog Merchants'),
			(14,5965,'Direct Marketing - Catalog and Retail Merchants (both)'),
			(14,5966,'Direct Marketing - Outbound Telemarketing Merchants'),
			(14,5967,'Direct Marketing - Inbound Telemarketing Merchants'),
			(14,5968,'Direct Marketing - Continuity/Subscription Merchants'),
			(14,5969,'Direct Marketing - Not Elsewhere Classified'),
			(15,5712,'Furniture, Home Furnishings and Equipment Stores, and Furniture Manufacturers (except Appliances)'),
			(15,5713,'Floor Covering Stores'),
			(15,5714,'Drapery, Window Covering, and Upholstery Stores'),
			(15,5718,'Fireplaces, Fireplace Screens and Accessories Stores'),
			(15,5719,'Miscellaneous Home Furnishings Specialty Stores'),
			(15,5722,'Household Appliance Stores'),
			(15,5732,'Electronics Stores'),
			(15,5733,'Music Stores - Musical Instruments, Pianos, and Sheet Music'),
			(15,5734,'Computer Software Stores'),
			(15,5735,'Record Stores'),
			(15,5912,'Drug Stores and Pharmacies'),
			(15,5921,'Package Stores - Beer, Wine, and Liquor'),
			(15,5931,'Used Merchandise and Secondhand Stores'),
			(15,5932,'Antique Shops - Sales, Repairs, and Restoration Services'),
			(15,5935,'Wrecking and Salvage Yards'),
			(15,5937,'Antique Reproduction Stores'),
			(15,5940,'Bicycle Shops - Sales and Service'),
			(15,5941,'Sporting Goods Stores'),
			(15,5942,'Book Stores'),
			(15,5943,'Stationery, Office, and School Supply Stores'),
			(15,5945,'Hobby, Toy, and Game Stores'),
			(15,5946,'Camera and Photographic Supply Stores'),
			(15,5947,'Gift, Card, Novelty, and Souvenir Stores'),
			(15,5948,'Luggage and Leather Goods Stores'),
			(15,5949,'Sewing, Needlework, Fabric, and Piece Goods Stores'),
			(15,5950,'Glassware and Crystal Stores'),
			(15,5970,'Artist Supply and Craft Stores'),
			(15,5971,'Art Dealers and Galleries'),
			(15,5972,'Stamp and Coin Stores'),
			(15,5973,'Religious Goods Stores'),
			(15,5975,'Hearing Aids Sales, Service and Supplies'),
			(15,5976,'Orthopedic Goods and Prosthetic Devices'),
			(15,5977,'Cosmetic Stores'),
			(15,5978,'Typewriter Stores - Sales, Service, and Rentals'),
			(15,5992,'Florists'),
			(15,5993,'Cigar Stores and Stands'),
			(15,5994,'News Dealers and Newsstands'),
			(15,5995,'Pet Shops, Pet Food and Supplies'),
			(15,5996,'Swimming Pools - Sales, Supplies, and Services'),
			(15,5997,'Electric Razor Stores - Sales and Service'),
			(15,5998,'Tent and Awning Stores'),
			(15,5999,'Miscellaneous and Specialty Retail'),
			(16,7210,'Laundry, Cleaning and Garment Services'),
			(16,7211,'Laundry Services (Family and Commercial)'),
			(16,7216,'Dry Cleaners'),
			(16,7217,'Carpet and Upholstery Cleaning'),
			(16,7221,'Photographic Studios'),
			(16,7251,'Shoe Repair Shops, Shoe Shine Parlors, and Hat Cleaning Shops'),
			(16,7276,'Tax Preparation Services'),
			(16,7278,'Buying and Shopping Services and Clubs'),
			(16,7296,'Clothing Rental - Costumes, Uniforms, and Formal Wear'),
			(16,7298,'Health and Beauty Spas'),
			(16,7299,'Miscellaneous Personal Services - Not Elsewhere Classified'),
			(17,6300,'Insurance Sales, Underwriting, and Premiums'),
			(17,8011,'Doctors and Physicians - Not Elsewhere Classified'),
			(17,8021,'Dentists and Orthodontists'),
			(17,8031,'Osteopaths'),
			(17,8041,'Chiropractors'),
			(17,8042,'Optometrists and Ophthalmologists'),
			(17,8043,'Opticians, Optical Goods, and Eyeglasses'),
			(17,8049,'Podiatrists and Chiropodists'),
			(17,8050,'Nursing and Personal Care Facilities'),
			(17,8062,'Hospitals'),
			(17,8071,'Medical and Dental Laboratories'),
			(17,8099,'Medical Services and Health Practitioners - Not Elsewhere Classified'),
			(17,8111,'Legal Services and Attorneys'),
			(17,8351,'Child Care Services'),
			(17,8734,'Testing Laboratories - Non-Medical'),
			(17,8911,'Architectural, Engineering, and Surveying Services'),
			(17,8931,'Accounting, Auditing, and Bookkeeping Services'),
			(17,8999,'Professional Services - Not Elsewhere Classified'),
			(18,5311,'Department Stores'),
			(18,5598,'Snowmobile Dealers'),
			(18,5621,'Women''s Ready To Wear Shoes'),
			(18,5661,'Shoe Stores'),
			(18,5681,'Furriers'),
			(18,5698,'Wig and Toupee Stores'),
			(18,5944,'Jewelry'),
			(18,6211,'Securities - Brokers and Dealers'),
			(18,7230,'Beauty and Barber Shops'),
			(18,7261,'Funeral Services'),
			(19,5933,'Pawn Shops'),
			(19,7273,'Dating and Escort Services'),
			(19,7277,'Debt and Marriage Counseling Services'),
			(19,7297,'Massage Parlors'),
			(19,7995,'Betting (including Lottery tickets, Casino gaming chips, Off-Track Betting, and wagers at Race Tracks)'),
			(19,9223,'Bail and Bond Payments'),
			(20,2741,'Miscellaneous Publishing and Printing Services'),
			(20,2791,'Typesetting, Platemaking, and Related Services'),
			(21,7531,'Automotive Body Repair Shops'),
			(21,7534,'Tire Re-Treading and Repair Shops'),
			(21,7535,'Automotive Paint Shops'),
			(21,7538,'Automotive Service Shops (Non-Dealer)'),
			(21,7542,'Car Washes'),
			(21,7549,'Towing Services'),
			(21,7622,'Electronics Repair Shops'),
			(21,7623,'Air Conditioning and Refrigeration Repair Shops'),
			(21,7629,'Electrical and Small Appliance Repairs'),
			(21,7631,'Watch, Clock, and Jewelry Repair Shops'),
			(21,7641,'Furniture - Re-Upholstery, Repair, and Refinishing'),
			(21,7692,'Welding Services'),
			(21,7699,'Miscellaneous Repair Shops and Related Services'),
			(22,5811,'Caterers'),
			(22,5812,'Eating Places, and Restaurants'),
			(22,5813,'Drinking Places (Alcoholic Beverages) - Bars, Taverns, Nightclubs, Cocktail Lounges, and Discotheques'),
			(22,5814,'Fast Food Restaurants'),
			(23,5200,'Home Supply Warehouse Stores'),
			(23,5211,'Lumber and Building Materials Stores'),
			(23,5231,'Glass, Paint, and Wallpaper Stores'),
			(23,5251,'Hardware Stores'),
			(23,5261,'Lawn and Garden Supply Stores (including Nurseries)'),
			(23,5271,'Mobile Home Dealers'),
			(23,5300,'Wholesale Clubs'),
			(23,5309,'Duty Free Stores'),
			(23,5310,'Discount Stores'),
			(23,5331,'Variety Stores'),
			(23,5399,'Miscellaneous General Merchandise'),
			(23,5411,'Grocery Stores and Supermarkets'),
			(23,5422,'Freezer and Locker Meat Provisioners'),
			(23,5441,'Candy, Nut, and Confectionery Stores'),
			(23,5451,'Dairy Products Stores'),
			(23,5462,'Bakeries'),
			(23,5499,'Miscellaneous Food Stores - Convenience Stores and Specialty Markets'),
			(24,4829,'Wire Transfers and Money Orders'),
			(24,6010,'Financial Institutions - Manual Cash Disbursements'),
			(24,6011,'Financial Institutions - Automated Cash Disbursements'),
			(24,6012,'Financial Institutions - Merchandise and Services'),
			(24,6051,'Non Financial Institutions - Foreign Currency, Money Orders, Scrip, and Travelers’ Checks (not Wire Transfers)'),
			(25,4812,'Telecommunication Equipment and Telephone Sales'),
			(25,4814,'Telecommunications Services - Local and Long Distance Calls), Credit Card Calls, Calls Through use of Magnetic-Stripe-Reading Telephones, and Fax Services'),
			(25,4815,'Monthly Summary Telephone Charges'),
			(25,4816,'Comp Network/Information Services'),
			(26,4011,'Railroads'),
			(26,4111,'Local and Suburban Commuter Passenger Transportation (including Ferries)'),
			(26,4112,'Passenger Railways'),
			(26,4119,'Ambulance Services'),
			(26,4121,'Taxicabs and Limousines'),
			(26,4131,'Bus Lines'),
			(26,4214,'Motor Freight Carriers and Trucking - Local and Long Distance, Moving and Storage Companies, and Local Delivery\'),
			(26,4215,'Courier Services - Air and Ground, and Freight Forwarders'),
			(26,4225,'Public Warehousing and Storage - Farm Products, Refrigerated Goods, and Household Goods'),
			(26,4457,'Boat Rentals and Leasing'),
			(26,4468,'Marinas, Marine Service, and Supplies'),
			(26,4582,'Airports, Flying Fields, and Airport Terminals'),
			(26,4722,'Travel Agencies and Tour Operators'),
			(26,4784,'Tolls and Bridge Fees'),
			(26,4789,'Transportation Services - Not Elsewhere Classified'),
			(26,7523,'Parking Lots and Garages'),
			(27,4821,'Telegraph Services'),
			(27,4899,'Cable and Other Pay Television Services'),
			(27,4900,'Utilities - Electric, Gas, Water, and Sanitary'),
			(27,5983,'Fuel Dealers - Fuel Oil, Wood, Coal, and Liquefied Petroleum'),
			(28,0743,'Wine Producers'),
			(28,0744,'Champagne Producers'),
			(28,5021,'Office and Commercial Furniture'),
			(28,5039,'Construction Materials - Not Elsewhere Classified'),
			(28,5044,'Office, Photographic, Photocopy, and Microfilm Equipment'),
			(28,5045,'Computers, Computer Peripheral Equipment, and Software'),
			(28,5046,'Commercial Equipment - Not Elsewhere Classified'),
			(28,5047,'Dental, Laboratory, Medical, and Ophthalmic Hospital Equipment and Supplies'),
			(28,5051,'Metal Service Centers and Offices'),
			(28,5065,'Electrical Parts and Equipment'),
			(28,5072,'Hardware Equipment and Supplies'),
			(28,5074,'Plumbing and Heating Equipment and Supplies'),
			(28,5085,'Industrial Supplies - Not Elsewhere Classified'),
			(28,5094,'Precious Stones and Metals, Watches, and Jewelry'),
			(28,5099,'Durable Goods - Not Elsewhere Classified'),
			(28,5111,'Stationery, Office Supplies, Printing and Writing Paper'),
			(28,5122,'Drugs, Drug Proprietors, and Druggists’ Sundries'),
			(28,5131,'Piece Goods, Notions, and Other Dry Goods'),
			(28,5137,'Men’s, Women’s, and Children’s Uniforms and Commercial Clothing'),
			(28,5139,'Commercial Footwear'),
			(28,5169,'Chemicals and Allied Products - Not Elsewhere Classified'),
			(28,5172,'Petroleum and Petroleum Products'),
			(28,5192,'Books, Periodicals, and Newspapers'),
			(28,5193,'Florists’ Supplies, Nursery Stock, and Flowers'),
			(28,5198,'Paints, Varnishes, and Supplies'),
			(28,5199,'Non-Durable Goods - Not Elsewhere Classified'),
			(28,5715,'Alcoholic Beverage Wholesalers')
			

END TRY
BEGIN CATCH
    EXEC dbo.PrintError
    EXEC dbo.LogError
END CATCH