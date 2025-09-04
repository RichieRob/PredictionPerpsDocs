## Applications

### 1. Reform UK Voting Intention in Weekly Poll
Weekly poll using one of the main pollsters. Used for political forecasting and hedging.

**Events**: 

 - Weekly poll percentage for Reform UK, in 0.1% increments $X_t \in \{0, 0.1, \dots, 100\}, m = 100$.

**Value**:

- $S_t = X_t$ (0–100).

**Complement**: 

- $\overline{S}_t = 100 - S_t$.

**Daily Payout Ratios**: 

- $\rho_T = \tfrac{S_t}{100}$, $\rho_{\overline{T}} = \tfrac{\overline{S}_t}{100}$

**Behaviour**: 

- $\rho_T$ and $\rho_{\overline{T}}$ remain fixed between polls

**Price Meaning**:

- P(T) reflects a discounted long term opinion on the performance of Reform UK

**Peformance Outline**: 

- If YouGov reports 26.3% support ($S_t = 26.3$)
- then $\overline{S}_t = 73.7$
- $\rho_T = 0.263$
- $\rho_{\overline{T}} = 0.737$. 
- $T$ holders (bullish on Reform UK) get ~26.3% of $r_t$
- $\overline{T}$ holders ~73.7%.

**Application**

- Analysts hedge campaign risks
- Users speculate on performance
- Each new poll updates ratios.

---

### 2. Liverpool’s Points in the Premier League
Tracks Liverpool’s points over a rolling 38 matches period.

**Events**: 

 - Match points, in increments of 0, 1, or 3 for loss, draw, or win ($X_t \in \{0, 1, 3\}, m = 3$).

**Value**:  

- $S_t = \sum_{k=0}^{37} X_{t-k}$  
- $0 \leq S_t \leq 114$  
- $n = 38$  

**Complement**: 

- $\overline{S}_t = 114 - S_t$.

**Daily Payout Ratios**: 

- $\rho_T = \tfrac{S_t}{114}$, $\rho_{\overline{T}} = \tfrac{\overline{S}_t}{114}$

**Behaviour**: 

- $\rho_T$ and $\rho_{\overline{T}}$ remain fixed between matches

**Price Meaning**:

- P(T) reflects a discounted long term opinion on Liverpool’s performance

**Peformance Outline**: 

- If Liverpool has scored 80 points in the last rolling 38 games ($S_t = 80$)
- then $\overline{S}_t = 114 - 80 = 34$
- $\rho_T \approx 0.702$
- $\rho_{\overline{T}} \approx 0.298$. 
- $T$ holders (bullish on Liverpool) get ~70.2% of $r_t$
- $\overline{T}$ holders ~29.8%.

**Application**

- Fans speculate on team performance
- Institutions hedge exposure
- Each new match updates ratios.

---

### 3. Cooling Degree Days in New York (Rolling 30 Days)
Tracks cooling demand over a rolling 30-day period using NOAA data for energy cost hedging.

**Events**: 

 - Daily CDD, $X_t = \max(0, T_t - 18)$, in °C, capped at 30 ($X_t \in \{0, 0.1, \dots, 30\}, m = 30$).

**Value**:  

- $S_t = \sum_{k=0}^{29} X_{t-k}$  
- $0 \leq S_t \leq 900$  
- $n = 30$  

**Complement**: 

- $\overline{S}_t = 900 - S_t$.

**Daily Payout Ratios**: 

- $\rho_T = \tfrac{S_t}{900}$, $\rho_{\overline{T}} = \tfrac{\overline{S}_t}{900}$

**Behaviour**: 

- $\rho_T$ and $\rho_{\overline{T}}$ update daily with new temperature data

**Price Meaning**:

- P(T) reflects a discounted long term opinion on cooling demand

**Peformance Outline**: 

- If NOAA reports 150 CDD over 30 days ($S_t = 150$)
- then $\overline{S}_t = 900 - 150 = 750$
- $\rho_T \approx 0.167$
- $\rho_{\overline{T}} \approx 0.833$. 
- $T$ holders (bullish on high cooling demand) get ~16.7% of $r_t$
- $\overline{T}$ holders ~83.3%.

**Application**

- Energy firms hedge heatwave costs
- Speculators trade on weather forecasts
- Each new daily temperature updates ratios.

---

### 4. Cooling Degree Days in New York for August
Tracks cooling demand for August using NOAA data for seasonal hedging.

**Events**: 

 - Daily CDD, $X_t = \max(0, T_t - 18)$, in °C, capped at 30 ($X_t \in \{0, 0.1, \dots, 30\}, m = 30$).

**Value**:  

- $S_t = \sum_{k=0}^{30} X_{t-k}$  
- $0 \leq S_t \leq 930$  
- $n = 31$  

**Complement**: 

- $\overline{S}_t = 930 - S_t$.

**Daily Payout Ratios**: 

- $\rho_T = \tfrac{S_t}{930}$, $\rho_{\overline{T}} = \tfrac{\overline{S}_t}{930}$

**Behaviour**: 

- $\rho_T$ and $\rho_{\overline{T}}$ adjust daily in August, fixed otherwise

**Price Meaning**:

- P(T) reflects a discounted long term opinion on August cooling demand

**Peformance Outline**: 

- If NOAA reports 200 CDD for August ($S_t = 200$)
- then $\overline{S}_t = 930 - 200 = 730$
- $\rho_T \approx 0.215$
- $\rho_{\overline{T}} \approx 0.785$. 
- $T$ holders (bullish on high cooling demand) get ~21.5% of $r_t$
- $\overline{T}$ holders ~78.5%.

**Application**

- Energy retailers hedge summer demand
- Speculators take positions on August weather
- Each new daily temperature in August updates ratios.

---

### 5. Inflation Rate
Tracks quarterly inflation rates using U.S. Bureau of Labor Statistics CPI data for economic hedging.

**Events**: 

 - Quarterly inflation rate, in 0.1% increments ($X_t \in \{0, 0.1, \dots, 10\}, m = 10$).

**Value**:  

- $S_t = X_t$  
- $0 \leq S_t \leq 10$

**Complement**: 

- $\overline{S}_t = 10 - S_t$.

**Daily Payout Ratios**: 

- $\rho_T = \tfrac{S_t}{10}$, $\rho_{\overline{T}} = \tfrac{\overline{S}_t}{10}$

**Behaviour**: 

- $\rho_T$ and $\rho_{\overline{T}}$ remain fixed between quarterly reports

**Price Meaning**:

- P(T) reflects a discounted long term opinion on inflation trends

**Peformance Outline**: 

- If CPI reports 3.2% inflation ($S_t = 3.2$)
- then $\overline{S}_t = 10 - 3.2 = 6.8$
- $\rho_T = 0.32$
- $\rho_{\overline{T}} = 0.68$. 
- $T$ holders (bullish on rising inflation) get ~32% of $r_t$
- $\overline{T}$ holders ~68%.

**Application**

- Investors hedge inflation costs
- Speculators take positions on economic stability
- Each new quarterly report updates ratios.


### 6. Self-Referencing Popularity Index for Taylor Swift
Tracks public opinion on Taylor Swift's anticipated future popularity through a self-referencing asset, useful for sentiment analysis and cultural hedging.

**Events**: 

- No external events; self-referencing based on market price of $T$
 - $X_t \in \{0, 0.01, \dots, 1\}, m = 100$.

**Value**:  

- $S_t = P(T)$  
- $0 \leq S_t \leq 1$  
- $n = 1$  

**Complement**: 

- $\overline{S}_t = 100 - S_t$.

**Daily Payout Ratios**: 

- $\rho_T = {S_t} = P(T)$
-  $\rho_{\overline{T}} = {\overline{S}_t} = 1 - P(T)$

**Behaviour**: 

- $\rho_T$ and $\rho_{\overline{T}}$ update dynamically with changes in $P(T)$, creating a feedback loop

**Price Meaning**:

- $P(T)$ reflects a discounted anticipation of Taylor Swift’s future popularity

**Peformance Outline**: 

- If the current market price $P(T) = 0.85$ ($S_t = 0.85$)
- then $\overline{S}_t = 1 - 0.85 = 0.15$
- $\rho_T = 0.85$
- $\rho_{\overline{T}} = 0.15$. 
- $T$ holders (bullish on Taylor Swift’s future popularity) get ~85% of $r_t$
- $\overline{T}$ holders ~15%.

**Application**

- Fans and media speculate on future cultural relevance
- Brands hedge endorsement risks
- Market dynamics drive updates through trading activity.