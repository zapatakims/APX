This report looks at a 7-day window period; i.e., 7 days prior to and after the report run-date. We need to calculate the Distribution Day in order to determine if the distribution was paid or is approaching.

Distribution Day
The distribution day is derived from a combination of the values DistDay[X] and DistFrequency[X]. 
DistDay
DistDay is an integer that represents the day of the month:
-1 = end of the last month
0 = end of this month
n = nth day of this month

DistFrequency
Frequency of the distribution denoted monthly, quarterly, annually, etc. For example, if the DistFrequency value is set to "Monthly", the client is obligated to pay out on a distribution each month. If quarterly for the months of Jan, Apr, Jul, Oct, the client is obligated to pay out on a distribution for those months only. The report logic will filter out any portfolios/clients that whose distribution frequency does not fall within the month that the report is run for.

For example, if the report is run as of February 28, and portfolio smith.cli has a DistFrequency set to Qrt-JAN-APR-JUL-OCT, this portfolio will be excluded from evaluation.

Paid
A distribution is considered "paid" when the Distribution Day occured on or 7 days prior to the report run-date.

Approaching
A distribution is considered "approaching" when the Distribution Day occurs within 7 days after the report run-date.

Not Distributed
When DistNet is not defined.
