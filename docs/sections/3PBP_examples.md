## PBP Examples



### Example 1: Reform UK Voting Intention in Political Polls
This PBP models the percentage of voters intending to vote for Reform UK in weekly political polls. Each poll is a time step \( t \), with the outcome being the percentage of respondents supporting Reform UK, reported in increments of 0.1%, so:

$$
X_t \in \{0, 0.1, 0.2, \dots, 99.8, 99.9, 100\}
$$

with maximum \( m = 100 \). The interval is defined by \( a = 0 \) (no support) and \( b = 100 \) (full support). Since each poll is a single event (\( n = 1 \)), the value \( S \) is the outcome of the last poll:

$$
S = X_t, \quad 0 \leq S \leq 100.
$$

The complementary measure, \( \overline{S} = 100 - S \), represents the percentage of voters not supporting Reform UK. For example, if a poll shows 26.3% support for Reform UK, then:

$$
\overline{S} = 100 - 26.3 = 73.7
$$

This pair \( (26.3, 73.7) \) reflects Reform UK’s voter support versus the portion of voters favoring other parties or none.

### Example 2: Liverpool’s Points in the English Premier League
This PBP models the points scored by Liverpool in their last 38 matches in the English Premier League. Each match is a time step \( t \), with Liverpool earning points: 0 for a loss, 1 for a draw, or 3 for a win, so the outcome is:

$$
X_t \in \{0, 1, 3\}
$$

with maximum \( m = 3 \). The interval is defined by \( a = 0 \) (loss) and \( b = 3 \) (win). Over 38 matches (\( n = 38 \)), total points \( S \) are:

$$
S = \sum_{k=0}^{37} X_{t-k}, \quad 0 \leq S \leq 3 \cdot 38 = 114.
$$

The complementary measure, \( \overline{S} = 114 - S \), represents unearned points. For example, if Liverpool scores 80 points, then:

$$
\overline{S} = 114 - 80 = 34
$$

This pair \( (80, 34) \) reflects Liverpool’s points earned versus points missed.



### Example 3: Cooling Degree Days in New York

#### Cooling Degree Days (CDD) Definition
Cooling Degree Days (CDD) measure the demand for cooling based on how much warmer the average daily temperature is compared to a baseline of 18°C. For a given day, CDD is calculated as the difference between the average daily temperature and 18°C, or zero if the temperature is 18°C or cooler. This quantifies the energy needed for air conditioning in warmer climates.

This PBP models the total Cooling Degree Days (CDD) in New York over a rolling 30-day period. Each day is a time step \( t \), with the outcome being the CDD, calculated as \( X_t = \max(0, T_t - 18) \), where \( T_t \) is the average daily temperature in °C, capped at 30 CDD per day to reflect realistic temperatures. Thus:

$$
X_t \in \{0, 0.1, 0.2, \dots, 29.8, 29.9, 30\}
$$

with maximum \( m = 30 \). The interval is defined by \( a = 0 \) (no cooling needed) and \( b = 30 \) (maximum daily CDD). Over a 30-day window (\( n = 30 \)), total CDD \( S \) is:

$$
S = \sum_{k=0}^{29} X_{t-k}, \quad 0 \leq S \leq 30 \cdot 30 = 900.
$$

The complementary measure, \( \overline{S} = 900 - S \), represents the shortfall from the maximum possible CDD. For example, if the total CDD over 30 days is 150, then:

$$
\overline{S} = 900 - 150 = 750
$$

This pair \( (150, 750) \) reflects the cooling demand versus the unused cooling capacity over the period.

#### Note on Cyclic PBPs
Some PBPs feature significant gaps between cycles of events, during which no new outcomes occur, but the values of \( S \) and \( \overline{S} \) remain defined and fixed. For example, in the Liverpool Premier League case (Example 2), points are accumulated during the season’s matches, but between seasons, no matches occur, and the values of \( S \) and \( \overline{S} \) persist until the next season begins. Similarly, a PBP can track metrics over a specific period each year, such as Cooling Degree Days for August, with values updating during the period and remaining constant until the next cycle, as shown in Example 4.


### Example 4: Cooling Degree Days in New York for August
This PBP models the total Cooling Degree Days (CDD) in New York for the month of August, a fixed 31-day period each year. Each day in August is a time step \( t \), with the outcome being the CDD, calculated as \( X_t = \max(0, T_t - 18) \), where \( T_t \) is the average daily temperature in °C, capped at 30 CDD per day. Thus:

$$
X_t \in \{0, 0.1, 0.2, \dots, 29.8, 29.9, 30\}
$$

with maximum \( m = 30 \). The interval is defined by \( a = 0 \) (no cooling needed) and \( b = 30 \) (maximum daily CDD). Over the 31 days of August (\( n = 31 \)), total CDD \( S \) is:

$$
S = \sum_{k=0}^{30} X_{t-k}, \quad 0 \leq S \leq 30 \cdot 31 = 930.
$$

The complementary measure, \( \overline{S} = 930 - S \), represents the shortfall from the maximum possible CDD. For example, if the total CDD for August is 200, then:

$$
\overline{S} = 930 - 200 = 730
$$

This pair \( (200, 730) \) reflects the cooling demand for August versus the unused cooling capacity. After August, \( S \) and \( \overline{S} \) remain fixed until the next August, illustrating a PBP with a yearly cycle and gaps between event periods.