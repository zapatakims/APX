######################################
##      Created on 2014/10/26       ##
##      Version 1.0                 ##
##                                  ##
##      CONTENTS OF THIS FILE       ##
##      * FILE LIST                 ##
##      * INSTALLATION              ##
##      * DESIGN                    ##
##      * EXPECTED BOTTLENECKS      ##
##                                  ##
######################################

1. FILE LIST
*********************
    mds_DARMD.rdl                           SSRS RDL file.
    RMD10Yr.csv                             Normalized RMD 10 year factor table, including owner and spouse age and multiplier.
    RMDInherited.csv                        RMD Inherited factor table, including age and multiplier.
    RMDNormal.csv                           RMD Normal factor table, including age and multiplier.
    RMD_Table_Script.sql                    SQL Script to bulk load the above 3 CSV files into the APXFirm database as tables within the APXUserCustom schema.
    APXUserCustom.DARMD.sql                 SQL stored procedure that contains the core report logic for mds_DARMD.rdl.
    APXUserCustom.fGetRMDMultiplier.sql     SQL scalar function that returns the multiplier value based on input values.

2. INSTALLATION
*********************
    You must run the mds_DARMD.exe file from the SQL server. You will need administrative access to the report server, DB server, and APX in order to successfully install the report. 

	A. Steps
		i. Download the ZIP file containing the report files, and unzip the contents to the C:\Temp\ folder. If the C:\Temp folder doesn't already exist, you must create one.
		ii. Run the mds_DARMD.exe file and enter the appropriate values at each prompt.
		iii. After the mds_DARMD.exe completes, log into APX and register the "mds_DARMD" SSRS report. For more information, refer to APX Help.
   
3. DESIGN
*********************
    A. Report Parameters
        This is a one-date, management-mode holdings report with the following input parameters:
        i. Required
            a. @SessionGuid - standard SessionID parameter.
            b. @Portfolios - portfolio/s
            c. @ToDate - Portfolio "As Of Date"
            d. @ReportingCurrencyCode - self-explanatory
            
        ii. Optional
            e. @FeeMethod - Net/Gross of fees; for contributions/withdrawals calculation.
            f. @IncludeClosedPortfolios - self-explanatory
            g. @IncludeUnsupervisedAssets - self-explanatory
            h. @AccruedInterestID - Interest accrual method to calculate market value (AI is included).
            i. @UseSettlementDate - trade/settle date.
            j. @LocaleID - Locale.
            k. @PriceTypeID - Price set.
            l. @ShowCurrencyFullPrecision - Precision.
            m. @OverridePortfolioSettings - report settings override portfolio settings.
            n. @ReportTitle - Default to "Required Minimum Distributions".

    B. Page Header
        The page header will display the: 
            i. Report Title
            ii. Year of "Portfolio As Of Date"
            iii. Firm Logo
            iv. Vertical separator image
        
    C. Page Footer
        Footer displays standard firm name and top border.

    D. Fonts and Styling
        This report uses the standard SSRS font styling functionality as in standard SSRS reports.

    E. Report Body
        i. Data Filters
            Only portfolios with TaxStatus = "Deferred" and portfolio owner contacts with Custom10 != '' will appear on this report. Closed portfolios on or before the As Of Date can be included based on the @IncludeClosedPortfolios parameter definition.
        
        ii. Report Columns
            a. CID = BlBkCID; i.e., Custom01 field under Contact.
            b. PM = First 2 characters of the Custom02 field under Contact. This will be shown in ALL-CAPS.
            c. Owner = Portfolio Owner last name, first name and middle initial. A dark red "D" will be prepended if the client is deceased (DOD <> '').
            d. DOB = BirthDate under Contact.
            e. DOD = Custom11 field under Contact.
            f. Age = calculated age rounded to 2 decimal places.
            g. Location = Default broker. This value is not accessible for some reason. Investigating...
            h. MA = Custom field "ManagementAgreement" under Portfolio.
            i. Acct = PortfolioBaseCode.
            j. Type = PortfolioTypeCode.
            k. Balance = MarketValue * RMD Value (see RMD below).
            l. Long Out = "LO" and "TO" trade amounts from the beginning of the year to Portfolio As Of Date; e.g., 1/1/2012 - 12/31/2012.
            m. Note = Calculated field; i.e., Balance - RMD.

        iii. RMD
            The RMD value is determined based on a number of factors. The following if-else statement will illustrate the report logic:
            -----------------------------------------------------------------------------------------
            |   if PortfolioTypeCode is not like 'Inherited'                                        |
            |       if the age difference between owner and spouse > 10 years,                      |
            |           multiplier = value from RMD10Yr table where floor(owner's age) = age.       |
            |       else                                                                            |
            |           multiplier = value from RMDInherited table where floor(owner's age) = age.  |
            |   else                                                                                |
            |       multiplier = value from RMDNormal table where floor(owner's age) = age.         |
            -----------------------------------------------------------------------------------------
        
        iv. Grouping
            This report groups by portfolio owner, but the primary sort is done by PortfolioBaseIDOrder.

    F. SQL Objects
        i. APXUserCustom.DARMD.sql
            Makes asynchronous calls to invoke both the Appraisal and ContributionsWithdrawals batch accounting functions to retrieve holdings and LO/TO transactions for the period.
            Additional logic is included that retrieves all required custom/standard portfolio and contact-related field values to populate the report.
            
        ii. APXUserCustom.fGetRMDMultiplier
            Scalar function that references the 3 custom tables: APXUserCustom.RMD10Yr, APXUserCustom.RMDInherited, and APXUserCustom.RMDNormal, in order to resolve the RMD multiplier/factor.

4. EXPECTED BOTTLENECKS
*********************
    A. No corresponding RMD factor value
        If there is no corresponding value in the RMD tables, the RMD value will resolve 1.