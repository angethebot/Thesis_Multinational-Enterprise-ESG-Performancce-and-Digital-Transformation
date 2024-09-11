
*******************************************************************************************************************
*** Project title: How Does Digital Transformation Impact the ESG Performance of Chinese Multinational Enterprises (MNEs): Evidence from Chinese Listed MNEs ***
*******************************************************************************************************************
* Created by Yuxin Gong
* Student Number: 0191121034


* This code performs the data analysis for the undergraduate thesis of Yuxin Gong
	* set your working directory and folders before using
	* or change the paths for code to run

clear 
set more off
capture log close
set type double

	*** Set your working directory here
		
global path = "D:/Thesis"
global output = "$path/Descriptive_Statistics"
global input = "$path/Input"
global temp = "$path/Temp"
global figures = "$path/Figures"
global clean = "$path/Clean"
global regs = "$path/Regs"


******Please make sure this line stays the exact same ********
log using "$path/Logs/Thesis", replace

di c(current_time)

*****************************
***** 1. Data Cleaning & Preparation  *****
*****************************
		  ******************************************************
          *** 1 (a) Prepare control variables to sample file ***
          ******************************************************

				  **********************************
				  *** (i) Import all the excel files ***
				  **********************************
					/*the files data, control_initial, digital_A, digital_B, and esg_hz, esg_bb were pre-cleaned beforehand. Data contains the settled MNE samples and the variable "technology" which indicates whether the MNE is a tech company and is determined by the industry code from CSMAR as well as the specific service covered by it's ovearseas subsidiaries. control_initial contains the metrics needed to generate control variables. digiatl_A and digital_B contain different measurements of my independent variable, while esg_hz and esg_bb contain different measurements of my dependent variable.*/
				  
				  import excel "$input/data", firstrow clear
				  save "$input/data", replace
				  
				  import excel "$input/control_initial", firstrow clear
				  save "$input/control_initial", replace
				  
				  

				  import excel "$input/digital_A", firstrow clear
				  destring year, replace
				  codebook year
				  isid symbol year
				  duplicates list symbol year
				  * use isid and duplicates to check if symbol and year will uniquely identify each observations
				  save "$input/digital_A", replace
				  *list symbol if missing(real(symbol)) 

				  /*
				  import excel "$input/digital_B", firstrow clear
				  destring year, replace
				  describe
				  *codebook
				  drop if year == .
				  isid symbol year
				  duplicates list symbol year
				  save "$input/digital_B", replace
				  */
				  
				  import excel "$input/digital", firstrow clear
				  destring year, replace
				  describe
				  gen digital = ln(数字化转型程度)
				  *codebook
				  drop if year == .
				  isid symbol year
				  duplicates list symbol year
				  save "$input/digital", replace
				  
				  
				  import excel "$input/digital_sub", firstrow clear
				  describe
				  *codebook
				  isid symbol year
				  duplicates list symbol year
				  save "$input/digital_sub", replace
				  
				  import excel "$input/esg_hz", firstrow clear
				  codebook
				  rename ESG esg_hz
				  drop if symbol == ""
				  isid symbol year
				  duplicates list symbol year
				  save "$input/esg_hz", replace
				  
				  import excel "$input/esg_bb", firstrow clear
				  codebook
				  isid symbol year
				  duplicates list symbol year
				  save "$input/esg_bb", replace
				  
				  import excel "$input/medium1_innovation", firstrow clear
				  destring year Invig Umig Desig Invjg Umjg Desjg, replace
				  egen innovation_num = rowtotal(Invig-Desjg)
				  gen innovation = ln(innovation_num)
				  keep symbol year innovation innovation_num
				  *isid symbol year
				  duplicates drop symbol year, force
				  des
				  save "$input/innovation", replace
				  
				  import excel "$input/medium2_riskcontrol", firstrow clear
				  isid symbol year
				  save "$input/riskcontrol", replace

				  ***************************************************
				  ***** (ii) Merge Control Variables to Data file ****
				  ***************************************************
		  
				  use "$input/data", clear
				  describe
				  codebook symbol /*to see unique samples*/
				  * 690 observations in total, 115 sample x 6 years
				  summarize
				  merge 1:1 symbol year using "$input/control_initial"
				  * there are only two records in data file that can't be found in the control_initial file
				  list if _merge == 1
				  * I want to recognize which samples are missing on observation & in which year
				  * These two records are  巨化股份-2021, 三六零-2016. These two firms are missing on all the control variables. These two sample, 巨化股份 and 三六零, may need to be dropped since they cause this dataset to be unbalanced (A balanced panel (e.g., the first dataset above) is a dataset in which each panel member (i.e., person) is observed every year) 
				  keep if _merge == 3
				  drop _merge
				  * here I keep all records from data, and see what others will need to be dropped after I merge all the files.
				  save "$temp/data_control_initial", replace
				  
				  
				  ******************************************
				  ***** (iii) Generate Control Variables ****
				  ******************************************
				  use "$temp/data_control_initial", clear
				  gen size=ln(total_asset) /*公司规模: gen Size=ln(资产总计)*/
				  label var size "公司规模"
				  
				  destring found_year, replace
				  gen age=ln(2023-found_year+1) /*企业年龄: gen age=ln(当年年份-公司成立年份+1)*/
				  label var age "企业年龄"
				  
				  gen lev=liability/total_asset  /*资产负债率: gen Lev=负债合计/资产总计*/
				  label var lev "资产负债率"
				  
				  /*Growth: 营业收入增长率: 本年营业收入/上一年营业收入-1*/
				  label var growth "营业收入增长率"
				  
				  gen indep=indep_board_num/board_num /*独立董事比例: 独立董事除以总董事人数*/
				  label var indep "独立董事比例"
				  
				  rename dual dual_initial
				  gen dual = 1 if dual_initial == 1
				  replace dual = 0 if dual_initial == 2/*两职合一: 董事长与总经理是同一个人为l，否则为0*/
				  label var dual "是否董事长与总经理两职合一"
				  
				  
				  replace top1=top1/100
				  replace top3=top3/100
				  replace top5=top5/100
				  replace top10=top10/100/*股权集中度: top1/3/5/10: 前一/三/五/十大股东持股比例	第一大股东持股数量/总股数*/
				  
				  gen board = ln(board_num) /*董事会规模 董事会人数取自然对数*/
				  label var board "董事会规模-董事会人数的自然对数"
				  
				  keep symbol name year technology size age lev growth indep dual top* board
				  
				  save "$temp/data_control", replace
				  
  
		  
		  ******************************************************************************
          *** 1 (b) Merge independent variables & dependent variables to sample file ***
          ******************************************************************************
				  
				  ***************************
				  ** (i) Use Measurement A **
				  ***************************
				  /*
				  
				  use "$temp/data_control", clear
				  merge 1:1 symbol year using "$input/digital_A"
				  list if _merge == 1
				  *5 records in total missing on digitial variale: 招商港口2015, 招商港口2017, 兆驰股份 | 2020, 三六零 | 2016, 三六零 | 2017
				  keep if _merge == 3 
				  drop _merge
				  gen digital_A = ln(数字化转型程度A)
				  save "$temp/data_control_independentA", replace
				  
				  
				  use "$temp/data_control_independentA", clear
				  merge 1:1 symbol year using "$input/esg_hz" 
				  list if _merge == 1
				  keep if _merge == 3
				  drop _merge
				  
				  encode symbol, gen (symbol_code)
				  xtset symbol_code year 
				  * it is an unbalanced panel. I have documented the previous samples that have missing data, so I just drop those samples.
				  drop if name == "巨化股份" | name == "三六零" | name == "招商港口" | name == "兆驰股份" 
				  xtset symbol_code year
				  * now it is balanced panel
				  save "$temp/data_control_independentA_hz", replace
				  
				  */
				  
				  
				  /* Below is me trying out the panel data to test if it's significant*/
				  
				  /*
				  use "$temp/data_control_independentA_hz", clear
				  reg esg_hz digital_A size age lev growth indep dual top1 board technology
				  reg esg_hz 数字化转型程度A size age lev growth indep dual top1 board
				  
				  winsor2 size age lev growth indep top1 board
				  
				  xtreg esg_hz 数字化转型程度A size age lev growth indep dual top1 board if technology == 0
				  xtreg esg_hz 数字化转型程度A size age lev growth indep dual top1 board, fe
				  xtreg esg_hz 数字化转型程度A size age lev growth indep dual top1 board, re
				  
				  xtreg esg_hz digital_A size age lev growth indep dual top1 board
				  
				  xtreg esg_hz 数字化转型程度A size age lev growth indep dual top1 board
				  xtreg esg_hz 数字化转型程度A size age lev growth indep dual top1 board 
				  */
				  
				  ***********************************************
				  ** (i) Use Measurement from textual analysis **
				  ***********************************************
				  use "$temp/data_control", clear
				  merge 1:1 symbol year using "$input/digital"
				  list if _merge == 1
				  *4 records in total missing on digitial variale: 招商港口2016, 招商港口2017, 兆驰股份 | 2020,  三六零 | 2017
				  keep if _merge == 3 
				  drop _merge
				  save "$temp/data_control_independent", replace
				  
				  
				  use "$temp/data_control_independent", clear
				  merge 1:1 symbol year using "$input/esg_hz" 
				  list if _merge == 1
				  keep if _merge == 3
				  drop _merge
				 
				  encode symbol, gen (symbol_code)
				  xtset symbol_code year
				  drop if name == "巨化股份" | name == "三六零" | name == "招商港口" | name == "兆驰股份"		  
				  xtset symbol_code year 
				  * it is now a balanced panel
				  save "$temp/data_control_independent_hz", replace
				  
				   /* Below is me trying out the panel data to test if it's significant*/
				   /*
				  use "$temp/data_control_independentB_hz", clear
				  reg esg_hz 数字化转型程度B size age lev growth indep dual top1 board
				  reg esg_hz digital_B size age lev growth indep dual top1 board /*P=0,001   coef.=0.63*/
				  xtreg esg_hz 数字化转型程度 size age lev growth indep dual top1 board
				  xtreg esg_hz digital_B size age lev growth indep dual top1 board /*P=0.002   coef.=0.75*/
				  */
				  /* This dataset is so much more significant than digital_A*/
				  
				  
		  ****************************************************
          *** 1 (c) Prepare Variables for Robustness Check ***
          ****************************************************
		  
				  *******************************************************
				  *** (i) Separate Independent Variables from digital ***
				  *******************************************************
				  
				  use "$temp/data_control_independent_hz", clear
				  gen digital_1 = ln(数字技术应用)
				  gen digital_2 = ln(互联网商业模式)
				  gen digital_3 = ln(智能制造)
				  gen digital_4 = ln(现代信息系统)
				  
				  
				  ************************************************************
				  *** (ii) Different Indepedent Variables from digital_A ***
				  ************************************************************
				  * Digital A is also digital transformation metrics from textual analysis, but it's derived from different textual analysis dictionary
				  merge 1:1 symbol year using "$input/digital_A"
				  keep if _merge == 3
				  drop _merge
				  gen digital_A = ln(数字化转型程度A)
				  label var digital_A "digital_A"
				
				  
				  **************************************************
				  *** (ii) Different Indepedent Variables from digital_sub ***
				  **************************************************
				  merge 1:1 symbol year using "$input/digital_sub"
				  keep if _merge == 3
				  drop _merge
				  
				  
				  *********************************************************
				  *** (iii) Different Depedent Variables from Bloomberg ***
				  *********************************************************
				  merge 1:1 symbol year using "$input/esg_bb"
				  keep if _merge==3
				  drop _merge
				  rename ESG esg_bb
				  destring esg_bb, replace
				  label var esg_bb "ESG rating from Bloomberg"
				  label var esg_hz "ESG rating from Huazheng"
				  
				  save "$clean/data_control_independent_esg_complete", replace
		
		
		  ******************************************************
          *** 1 (d) Prepare variables for Mediation Analysis ***
          ******************************************************
		  
		  		  *****************************************
				  *** (i) Medium 1: Innovation variable ***
				  *****************************************
		          use "$clean/data_control_independent_esg_complete", clear
				  merge 1:1 symbol year using "$input/innovation"
				  keep if _merge==3
				  drop _merge
		  
		  		  ********************************************
				  *** (ii) Medium 2: Risk Control variable ***
				  ********************************************		
				  merge 1:1 symbol year using "$input/riskcontrol"
				  keep if _merge==3
				  drop _merge
				  
				  save "$clean/data_Mediation", replace
				  
		  
*************************************
***** 2. Descriptive Statistics *****
*************************************
use "$clean/data_Mediation", clear
		  
			*************************************************************************************
			***** 2(a) Descriptive Statistics of Independent Variable and Control Variables *****		
			*************************************************************************************
			
				**********************************************
				**** (i) Independent variables & Controls ****
				**********************************************
				
				* Descriptive Statistics of independent variables & controls
				
				codebook symbol
				codebook symbol if technology == 1
				/* there are 110 samples in total, with data from 2016-2021 which is 6 years. 23 firms are from technology industries, 87 are from non-technology industries.*/
				
				sum digital 数字化转型程度
				codebook digital
				
				tabstat technology
				list if missing(digital)
				/* there are 4 records with 数字化转型程度==0*/
				
				
				logout, save($output/digital_tech0) excel replace: tabstat digital if technology == 0, c(s) s(N mean sd min p50 max) format(%10.3f)
				log using "$path/Logs/Thesis", append
				logout, save($output/digital_tech1) excel replace: tabstat digital if technology == 1, c(s) s(N mean sd min p50 max) format(%10.3f)
				log using "$path/Logs/Thesis", append
				
				logout, save($output/digital_ESG0) excel replace: tabstat esg_hz if technology == 0, c(s) s(N mean sd min p50 max) format(%10.3f)
				log using "$path/Logs/Thesis", append
				logout, save($output/digital_ESG1) excel replace: tabstat esg_hz if technology == 1, c(s) s(N mean sd min p50 max) format(%10.3f)
				log using "$path/Logs/Thesis", append
				
				
				
				tabstat esg_hz digital growth top1 size age lev indep dual board, c(s) s(N mean sd min p50 max) format(%10.3f)
				logout, save($output/inde_summary) excel replace: tabstat esg_hz digital growth top1 size age lev indep dual board, c(s) s(N mean sd min p50 max) format(%10.3f)
				log using "$path/Logs/Thesis", append
				histogram digital, normal title("Distribution of the Independent Variable - digital")
				graph export "$figures/histogram_digital.png", replace
				* the independent variable is in an almost normal distribution, which is very suitable for an OLS regresion *
				

				correlate digital growth top1 size age lev indep dual board
				/* 由于控制变量比较多，所以提前看一看x之间的相关性，以避免多重共线性，但是从表中可以看出，x之间相关性并不大*/
				logout, save($output/inde_correlate) excel replace: correlate digital growth top1 size age lev indep dual board
				log using "$path/Logs/Thesis", append
				
				pwcorr digital growth top1 size age lev indep dual board
				logout, save($output/inde_pwcorr) excel replace: pwcorr digital growth top1 size age lev indep dual board
				log using "$path/Logs/Thesis", append
				/*查看简单相关系数，也并没有出现相关系数大于0.8的情况，初步判断没有多重共线性*/
				
				*以下做VIF检验
				qui reg esg_hz digital growth top1 size age lev indep dual board
				estat vif
				/* Mean Vif VIF的均值 = 1.29 < 2，说明没有多重共线性，并且每个VIF都<2，说明不存在多重共线性*/
				logout, save($output/inde_vif) excel replace: estat vif
				log using "$path/Logs/Thesis", append
				* Graphs of x variables x与时间的变化，
				tabulate symbol
				*xtline digital if technology == 0 , overlay
				
				xtline digital if symbol_code<11 , overlay title ("前10家样本数字化程度随时间变化趋势") xtitle("年份") ytitle("数字化程度") 
				graph export "$figures/digital_trend_random10.png", replace 
				*随机取一些样本看，企业的数字化程度随着时间有着略微上升的趋势
				* twoway scatter year digital
				* 计算每年样本企业的数字化平均值，查看随时间变化趋势
				bysort year: egen digital_avg = mean(digital)
				tabulate year digital_avg
				* 可以看到，六个值呈逐年上升的趋势
				xtline digital_avg if symbol_code==1, title ("平均数字化程度随时间变化趋势") xtitle("年份") ytitle("平均数字化程度") 
				graph export "$figures/digital_trend_avg.png", replace
				* 由于所有的企业都有着一样的数据，所以随机取一个企业看平均值变化，发现是一个很明显的上升趋势
				
				***********************************
				**** (ii) Dependent variables  ****
				***********************************
				bysort year: egen esg_hz_avg = mean(esg_hz)
				tabulate year esg_hz_avg
				xtline esg_hz_avg if symbol_code == 1, title ("平均ESG表现随时间变化趋势") xtitle("年份") ytitle("平均ESG表现——华证") 
				graph export "$figures/esg_hz_trend_avg.png", replace
				/*2021年有所下降，但是以往均一直上升*/
				
				*为了验证上升的趋势的猜想，选取了彭博的esg指标进行观测
				bysort year: egen esg_bb_avg = mean(esg_bb)
				tabulate year esg_bb_avg
				xtline esg_bb_avg if symbol_code == 1, title ("平均ESG表现随时间变化趋势") xtitle("年份") ytitle("平均ESG表现——彭博") 
				graph export "$figures/esg_bb_trend_avg.png", replace
				*结果证明，样本esg评分确实一直上升
				
				
				*x与y散点图*	
				twoway (scatter esg_hz digital) (lfit esg_hz digital), title("ESG-数字化转型拟合线") xtitle("数字化转型") ytitle("ESG评分") xlabel(0(1)7)
				graph export "$figures/digital_esg_hz_scatter.png", replace
			
			    *二者的散点图有点乱，但拟合线为一条轻微上升的直线。且二者单独随时间变化都是上升趋势，猜想二者为正相关关系
				
save "$clean/data_control_independent_esg_afterdes", replace

				

***********************************
***** 3. Regression Analysis  *****
***********************************
use "$clean/data_control_independent_esg_afterdes", clear			
				
				**********************************
				**** 3(a) Pre-regression Test ****
				**********************************
				
				* This section will run a few test to identify which regression model to use, the pooled regression, fixed effect, or random effect
				
				/*混合回归*/
				reg esg_hz digital size age lev growth indep dual top1 board /*P=0.001   coef.=0.63*/
				*F<0.05，且核心解释变量digital的P=0.001。该混合回归进一步证实猜想
				
				*********************
				*混合回归or固定效应 *
				*********************
				*检验F检验*
				xtreg esg_hz digital size age lev growth indep dual top1 board, fe
				estimates store FE
				*F检验原假设：所有ui都为0。由于F检验的p值为0.0000，所以强烈拒绝原假设，认为FE优于混合回归。缺点：没有使用稳健标准误，F检验不有效，因此使用LSDV法。
				
				**********************
				* 混合回归or随机效应 *
				**********************
				*LM检验
				xtreg esg_hz digital size age lev growth indep dual top1 board, re robust
				estimates store RE
				xttest0
				* LM检验，原假设不存在个体随机效应，P=0.0000，说明存在个体随机效应。在“混合回归”与“随机效应”中，选后者。
				
				**********************
				* 固定效应or随机效应 *
				**********************
				*hausman豪斯曼检验
				xtreg esg_hz digital size age lev growth indep dual top1 board,fe //固定效应估计
				estimates store FE //储存结果
				xtreg esg_hz digital size age lev growth indep dual top1 board,re //随机效应估计
				estimates store RE //储存结果
				hausman FE RE, constant sigmamore 
				*drop _Isymbol_co_2 - _est_RE
				//constant表示在比较系数估计值时包括常数项，sigmamore表示使用更有效率的那个估计量的方差估计
				*检验的原假设是应该采用随机效应,备则假设是固定效应。p值>0.1，说明无法原假设，从而使用随机效应。
				*但是很多时候计算出的统计量可能为负，这时候使用sigmamore或者stigmaless选项可以大大减少出现负值的可能性。
				
				
				******************************************
				**** 3(b) Regression Analysis基准回归 ****
				******************************************
				
						***********************
						***** (i) Model 1 *****
						***********************
						*"仅用解释变量回归"
						xtreg esg_hz digital, re
						outreg2 using "$regs/regression", excel replace ctitle(Model 1) /*P=0.002   coef.=0.0.996*/
						/* 首先只用解释变量对被解释变量进行回归，可以看到P值为0.000，非常显著*/
						
						
						************************
						***** (ii) Model 2 *****
						************************
						xtreg esg_hz digital size age lev growth 
						*xtreg esg_hz digital size age lev growth indep dual top1 board, fe
						outreg2 using "$regs/regression", excel append ctitle(Model 2)
						
						
						************************
						***** (iii) Model 3 *****
						************************
						xtreg esg_hz digital size age lev growth indep dual top1 board /*P=0.002   coef.=0.75*/
						*xtreg esg_hz digital size age lev growth indep dual top1 board, fe
						outreg2 using "$regs/regression", excel append ctitle(Model 3)
						
						*可以看到，digital的系数均为正，并且在99%的置信水平，0.01的显著性水平上显著
						
						
				*******************************************************
				**** 3(c) 异质性分析 Heterogeneity Check：分组回归 ****
				*******************************************************
		*由于科技企业和非科技企业对于数字化转型的应用以及程度有明显的不同，一般来讲科技企业的数字化转型程度最开始便会比非科技企业高，所以在对ESG表现的影响上，数字换转型的作用也应该会略有所不同。检查该异质性有助于为不同产业的企业改善ESG表现差异化战略设定提供建议。
				
				xtreg esg_hz digital size age lev growth indep dual top1 board if technology == 0
				outreg2 using "$regs/Heterogeneity", excel replace ctitle(Technology 0)
						
				xtreg esg_hz digital size age lev growth indep dual top1 board if technology == 1
				outreg2 using "$regs/Heterogeneity", excel append ctitle(Technology 1)
						/*非科技跨国企业，数字化转型对ESG表现的促进作用显著，而对于科技跨国公司，反而影响作用不显著。这里的非科技企业大部分为制造业、采矿业、贸易业等等，这个结果对企业以及产业的发展有着一定的意义*/
						
				xtreg esg_hz digital size age lev growth indep dual top1 board
				outreg2 using "$regs/covid", excel replace ctitle(ESG overall)
				xtreg esg_hz digital size age lev growth indep dual top1 board if year < 2020
				outreg2 using "$regs/covid", excel append ctitle(ESG before COVID)
				
				xtreg esg_hz digital size age lev growth indep dual top1 board if year > 2019
				
				gen digital2=digital*digital
				xtreg esg_hz digital digital2 size age lev growth indep dual top1 board if year > 2019
				
				
				
				
				
				
				/*
				reg esg_hz digital size age lev growth indep dual top1 board if year > 2020
				
				gen postcovid = 1 if year>2020
				replace postcovid = 0 if year <2021
				gen postcovidxdigital = postcovid*digital
				xtreg esg_hz digital postcovidxdigital postcovid size age lev growth indep dual top1 board
				
				xtreg esg_bb digital postcovidxdigital postcovid size age lev growth indep dual top1 board				
				
				*/
						
				
				  	
save "$clean/data_control_independent_esg_afterreg", replace				


********************************
***** 4. Robustness check  *****
********************************  
use "$clean/data_control_independent_esg_afterreg", clear		

				  
			  ***********************************************
			  ***** 4 (a) Replace independent variable  *****
			  ***********************************************
			          
					  
					  ***************************************************
					  ***** (i)) use separate independent variabla  *****
					  ***************************************************	  
				      *首先，使用四个关键词大类分别作为解释变量进行回归
					  /*
					  xtreg esg_hz digital_1 size age lev growth indep dual top1 board	 
					  outreg2 using "$regs/Robustx", excel replace ctitle(Digital 1)
					  xtreg esg_hz digital_2 size age lev growth indep dual top1 board		
					  outreg2 using "$regs/Robustx", excel append ctitle(Digital 2)
					  xtreg esg_hz digital_3 size age lev growth indep dual top1 board	
					  outreg2 using "$regs/Robustx", excel append ctitle(Digital 3)
					  xtreg esg_hz digital_4 size age lev growth indep dual top1 board
					  outreg2 using "$regs/Robustx", excel append ctitle(Digital 4)
					  
					  *其中两个为显著
					  */

					  
					  ***************************************************************************
					  ***** (ii) use a different independent variable from textual analysis *****
					  ***************************************************************************
					  *第二，换另外一种词频统计的x变量进行回归
					  gen digital_A_sub = 数字化转型程度A
					  xtreg esg_hz digital_A_sub size age lev growth indep dual top1 board /*P = 0.075*/
					  outreg2 using "$regs/Robustx", excel replace ctitle(Digital A)
					  *在90%的置信水平显著
					  
					  /*
					  xtreg esg_hz digital_A size age lev growth indep dual top1 board /*P = 0.797*/
					  */
					  
					  
					  *****************************************************************************
					  ***** (iii) use a different independent variable from asset calculation *****
					  *****************************************************************************
					  twoway scatter esg_hz digital
					  *考虑到该替换变量可能并非与ESG水平呈绝对的线性关系，加入二次项
					  gen digital_sub2=digital_sub*digital_sub
					  xtreg esg_hz digital_sub digital_sub2 size age lev growth indep dual top1 board
					  outreg2 using "$regs/Robustx", excel append ctitle(Digital sub)
					  *拐点在x=0.35处
					  histogram digital_sub
					  graph export "$figures/digital_sub.png", replace
					  tabstat digital_sub, s(p25 p50 p75 p90 p95 p99)
					  logout, save($output/digital_sub) excel replace:tabstat digital_sub, s(p25 p50 p75 p90 p95 p99)
					  log using "$path/Logs/Thesis", append
					  *可见，98%的x都处于拐点左边，即上升的区间
					 *可能的解释是，在拐点左边，企业的数字化资产占无形资产越高，越能够提升企业ESG表现，但是过了拐点，企业数字化资产过高，说明企业的业务范围并非常规范围，此时再增加数字化转型，对于企业ESG表现无促进作用反而降低。
					 
			  *********************************************
			  ***** 4 (a) Replace dependent variable  *****
			  *********************************************
			  *此处采取彭博的esg评分指数
			  
			  xtreg esg_bb digital  /*非常显著！！！*/
			  outreg2 using "$regs/Robusty", excel replace ctitle(ESG Bloomberg 1 )
			  xtreg esg_bb digital size age lev growth  /*非常显著！！！*/
			  outreg2 using "$regs/Robusty", excel append ctitle(ESG Bloomberg 2)
			  xtreg esg_bb digital size age lev growth indep dual top1 board /*非常显著！！！*/
			  outreg2 using "$regs/Robusty", excel append ctitle(ESG Bloomberg 3)
			  *是正系数，99%置信水平上显著促进
			  /* coef = 2.134529, P=0.000*/
			  
			  xtreg esg_bb digital size age lev growth indep dual top1 board if year < 2020
			  outreg2 using "$regs/Robusty", excel append ctitle(ESG before COVID)

		  
*********************************************************************
***** 5. How does the positive effect happens: Mesomeric effect *****
*********************************************************************
				  
				  *********************************
				  *** 5(a) Medium 1: Innovation ***
				  *********************************
				  
						  ****************
						  *** 逐步回归 ***
						  ****************
						  xtreg esg_hz digital size age lev growth indep dual top1 board /*digital显著 y = cX + e1*/
						  outreg2 using "$regs/mediation1", excel replace ctitle(Step 1)
						  xtreg innovation digital size age lev growth indep dual top1 board /*digital显著！y = aX + e2 */
						  outreg2 using "$regs/mediation1", excel append ctitle(Step 2)
						  xtreg esg_hz digital innovation size age lev growth indep dual top1 board /*这里digital不显著,而innovation显著 y = c'X + bM + e3*/
						  outreg2 using "$regs/mediation1", excel append ctitle(Step 3)
						  *完全中介效应
						  
						  *****************
						  *** Sobel检验 ***
						  *****************
						  *net install sgmediation2, from("https://tdmize.github.io/data/sgmediation2")
						  sgmediation2 esg_hz, mv(innovation) iv(digital) cv(size age lev growth indep dual top1 board )
						  outreg2 using "$regs/mediation1", excel append ctitle(Sobel)
						  *记得这里要改一下Sobel的那一列
						  *原假设：不存在中介效应，看Sobel的P值， P值=0.000 ，所以拒绝原假设，显著有中介效应
						  *但是这里proportion>1 是什么意思？？并且Ratio of indirect to direct effect=-1， 424Ratio of total to direct effect=

				  
				  ***********************************
				  *** 5(b) Medium 2: Risk Control ***
				  ***********************************
				          
						  ****************
						  *** 逐步回归 ***
						  ****************
						  xtreg esg_hz digital size age lev growth indep dual top1 board /*digital显著 y = cX + e1*/
						  outreg2 using "$regs/mediation2", excel replace ctitle(Step 1)
						  xtreg riskcontrol digital size age lev growth indep dual top1 board /*digital显著！y = aX + e2 */
						  outreg2 using "$regs/mediation2", excel append ctitle(Step 2)
						  xtreg esg_hz digital riskcontrol  size age lev growth indep dual top1 board /*这里digital显著,且riskcontrol显著 y = c'X + bM + e3*/
						  outreg2 using "$regs/mediation2", excel append ctitle(Step 3)
						  *为部分中介效应
						  
						  *****************
						  *** Sobel检验 ***
						  *****************
						  sgmediation2 esg_hz, mv(riskcontrol) iv(digital) cv(size age lev growth indep dual top1 board )
						  outreg2 using "$regs/mediation2", excel append ctitle(Sobel)
						  *Sobel的P值显著了，并且proportion也很正常
						  *这里记得要修改一下Sobel的那一列回归
						  
						  
						  
save "$clean/data_control_independent_esg_aftercheck", replace	

		  
********************************
***** 5. Endogeniety Check *****
********************************

***************************
***** 6. Implications *****
***************************




di c(current_time)


		  
log close

* EOF
