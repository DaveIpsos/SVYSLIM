
cd "C:\Users\Daves\OneDrive - Florida State University\SVY NEW"
use "ipums_data combined", clear
fre year

preserve
**********************************************************************
* Stage A *** Compile parameters/inputs for Level-weights calculations
**********************************************************************
keep if year == 2018

gen survey = 2018

* a_c_h completed clusters by strata
gen a_c_h=.
quietly levelsof strata, local(lstrata)
quietly foreach ls of local lstrata {
tab clusterno if strata==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if strata==`ls'
}

* A_h total number of census clusters by strata
gen A_h = 0
replace A_h = 2452 if strata == 1
replace A_h = 1138 if strata == 2
replace A_h = 2006 if strata == 3
replace A_h = 20850 if strata == 4
replace A_h = 5492 if strata == 5
replace A_h = 10354 if strata == 6
replace A_h = 11715 if strata == 7
replace A_h = 4556 if strata == 8
replace A_h = 2008 if strata == 9
replace A_h = 7211 if strata == 10
replace A_h = 5126 if strata == 11
replace A_h = 18319 if strata == 12
replace A_h = 3949 if strata == 13
replace A_h = 11930 if strata == 14
replace A_h = 2820 if strata == 15
replace A_h = 9988 if strata == 16
replace A_h = 2761 if strata == 17
replace A_h = 17124 if strata == 18
replace A_h = 7798 if strata == 19
replace A_h = 16288 if strata == 20
replace A_h = 1955 if strata == 21
replace A_h = 7539 if strata == 22
replace A_h = 1657 if strata == 23
replace A_h = 8943 if strata == 24
replace A_h = 3053 if strata == 25
replace A_h = 11870 if strata == 26
replace A_h = 2293 if strata == 27
replace A_h = 18900 if strata == 28
replace A_h = 9529 if strata == 29
replace A_h = 12263 if strata == 30
replace A_h = 16957 if strata == 31
replace A_h = 19402 if strata == 32
replace A_h = 6874 if strata == 33
replace A_h = 26442 if strata == 34
replace A_h = 2621 if strata == 35
replace A_h = 14020 if strata == 36
replace A_h = 2548 if strata == 37
replace A_h = 10231 if strata == 38
replace A_h = 3090 if strata == 39
replace A_h = 13942 if strata == 40
replace A_h = 2106 if strata == 41
replace A_h = 9463 if strata == 42
replace A_h = 18409 if strata == 43
replace A_h = 3498 if strata == 44
replace A_h = 11911 if strata == 45
replace A_h = 1977 if strata == 46
replace A_h = 9774 if strata == 47
replace A_h = 4223 if strata == 48
replace A_h = 10006 if strata == 49
replace A_h = 9567 if strata == 50
replace A_h = 908 if strata == 51
replace A_h = 16205 if strata == 52
replace A_h = 2628 if strata == 53
replace A_h = 6379 if strata == 54
replace A_h = 1410 if strata == 55
replace A_h = 14912 if strata == 56
replace A_h = 9008 if strata == 57
replace A_h = 9201 if strata == 58
replace A_h = 7964 if strata == 59
replace A_h = 4829 if strata == 60
replace A_h = 12480 if strata == 61
replace A_h = 12381 if strata == 62
replace A_h = 9438 if strata == 63
replace A_h = 2123 if strata == 64
replace A_h = 25424 if strata == 65
replace A_h = 0 if strata == 66
replace A_h = 7085 if strata == 67
replace A_h = 7408 if strata == 68
replace A_h = 8588 if strata == 69
replace A_h = 10667 if strata == 70
replace A_h = 19810 if strata == 71
replace A_h = 6097 if strata == 72
replace A_h = 22405 if strata == 73
replace A_h = 8701 if strata == 74

* M_h average number of households per cluster by strata
gen M_h = 0
replace M_h = 660 if strata== 1
replace M_h = 390 if strata== 2
replace M_h = 150 if strata== 3
replace M_h = 990 if strata== 4
replace M_h = 360 if strata== 5
replace M_h = 720 if strata== 6
replace M_h = 720 if strata== 7
replace M_h = 330 if strata== 8
replace M_h = 270 if strata== 9
replace M_h = 780 if strata== 10
replace M_h = 300 if strata== 11
replace M_h = 840 if strata== 12
replace M_h = 300 if strata== 13
replace M_h = 750 if strata== 14
replace M_h = 300 if strata== 15
replace M_h = 750 if strata== 16
replace M_h = 180 if strata== 17
replace M_h = 990 if strata== 18
replace M_h = 390 if strata== 19
replace M_h = 750 if strata== 20
replace M_h = 270 if strata== 21
replace M_h = 780 if strata== 22
replace M_h = 180 if strata== 23
replace M_h = 870 if strata== 24
replace M_h = 240 if strata== 25
replace M_h = 810 if strata== 26
replace M_h = 150 if strata== 27
replace M_h = 1020 if strata== 28
replace M_h = 600 if strata== 29
replace M_h = 690 if strata== 30
replace M_h = 660 if strata== 31
replace M_h = 930 if strata== 32
replace M_h = 270 if strata== 33
replace M_h = 990 if strata== 34
replace M_h = 180 if strata== 35
replace M_h = 870 if strata== 36
replace M_h = 240 if strata== 37
replace M_h = 870 if strata== 38
replace M_h = 210 if strata== 39
replace M_h = 870 if strata== 40
replace M_h = 240 if strata== 41
replace M_h = 840 if strata== 42
replace M_h = 960 if strata== 43
replace M_h = 210 if strata== 44
replace M_h = 900 if strata== 45
replace M_h = 180 if strata== 46
replace M_h = 750 if strata== 47
replace M_h = 330 if strata== 48
replace M_h = 540 if strata== 49
replace M_h = 630 if strata== 50
replace M_h = 90 if strata== 51
replace M_h = 1020 if strata== 52
replace M_h = 270 if strata== 53
replace M_h = 780 if strata== 54
replace M_h = 180 if strata== 55
replace M_h = 870 if strata== 56
replace M_h = 540 if strata== 57
replace M_h = 600 if strata== 58
replace M_h = 600 if strata== 59
replace M_h = 450 if strata== 60
replace M_h = 570 if strata== 61
replace M_h = 660 if strata== 62
replace M_h = 780 if strata== 63
replace M_h = 270 if strata== 64
replace M_h = 1500 if strata== 65
replace M_h = 90 if strata== 66
replace M_h = 540 if strata== 67
replace M_h = 570 if strata== 68
replace M_h = 510 if strata== 69
replace M_h = 570 if strata== 70
replace M_h = 810 if strata== 71
replace M_h = 270 if strata== 72
replace M_h = 900 if strata== 73
replace M_h = 360 if strata== 74

* m_c total number of completed households (added from the HR dataset)
gen m_c= 40427
* M total number of households in country
gen M = 28900492
* S_h households selected per stratum
gen S_h = 30
gen DHSwt = perweight

**********************************************************************
* Stage B *** Approximate Level-weights ***
**********************************************************************
* Steps to approximate Level-1 and Level-2 weights from Household or Individual Weights
*Step 1. De-normalize the final weight, using approximated normalization factor
gen d_HH = DHSwt * (M/m_c)
*Step 2. Approximate the Level-2 weight
* f the variation factor
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
* Calculating the level-weights based on different values of alpha
scalar alpha = 0.5
gen wt2 = (A_h/a_c_h)*(f^alpha)
*** 3 ***************************
gen wt1 = d_HH/wt2

***Save
save ipums_2018, replace

restore


preserve
**********************************************************************
* Stage A *** Compile parameters/inputs for Level-weights calculations
**********************************************************************
keep if year == 2013

gen survey = 2013

* a_c_h completed clusters by strata
gen a_c_h=.
quietly levelsof strata, local(lstrata)
quietly foreach ls of local lstrata {
tab clusterno if strata==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if strata==`ls'
}

* A_h total number of census clusters by strata
gen A_h = 0
replace A_h = 2452 if strata == 1
replace A_h = 1138 if strata == 2
replace A_h = 2006 if strata == 3
replace A_h = 20850 if strata == 4
replace A_h = 5492 if strata == 5
replace A_h = 10354 if strata == 6
replace A_h = 11715 if strata == 7
replace A_h = 4556 if strata == 8
replace A_h = 2008 if strata == 9
replace A_h = 7211 if strata == 10
replace A_h = 5126 if strata == 11
replace A_h = 18319 if strata == 12
replace A_h = 3949 if strata == 13
replace A_h = 11930 if strata == 14
replace A_h = 2820 if strata == 15
replace A_h = 9988 if strata == 16
replace A_h = 2761 if strata == 17
replace A_h = 17124 if strata == 18
replace A_h = 7798 if strata == 19
replace A_h = 16288 if strata == 20
replace A_h = 1955 if strata == 21
replace A_h = 7539 if strata == 22
replace A_h = 1657 if strata == 23
replace A_h = 8943 if strata == 24
replace A_h = 3053 if strata == 25
replace A_h = 11870 if strata == 26
replace A_h = 2293 if strata == 27
replace A_h = 18900 if strata == 28
replace A_h = 9529 if strata == 29
replace A_h = 12263 if strata == 30
replace A_h = 16957 if strata == 31
replace A_h = 19402 if strata == 32
replace A_h = 6874 if strata == 33
replace A_h = 26442 if strata == 34
replace A_h = 2621 if strata == 35
replace A_h = 14020 if strata == 36
replace A_h = 2548 if strata == 37
replace A_h = 10231 if strata == 38
replace A_h = 3090 if strata == 39
replace A_h = 13942 if strata == 40
replace A_h = 2106 if strata == 41
replace A_h = 9463 if strata == 42
replace A_h = 18409 if strata == 43
replace A_h = 3498 if strata == 44
replace A_h = 11911 if strata == 45
replace A_h = 1977 if strata == 46
replace A_h = 9774 if strata == 47
replace A_h = 4223 if strata == 48
replace A_h = 10006 if strata == 49
replace A_h = 9567 if strata == 50
replace A_h = 908 if strata == 51
replace A_h = 16205 if strata == 52
replace A_h = 2628 if strata == 53
replace A_h = 6379 if strata == 54
replace A_h = 1410 if strata == 55
replace A_h = 14912 if strata == 56
replace A_h = 9008 if strata == 57
replace A_h = 9201 if strata == 58
replace A_h = 7964 if strata == 59
replace A_h = 4829 if strata == 60
replace A_h = 12480 if strata == 61
replace A_h = 12381 if strata == 62
replace A_h = 9438 if strata == 63
replace A_h = 2123 if strata == 64
replace A_h = 25424 if strata == 65
replace A_h = 0 if strata == 66
replace A_h = 7085 if strata == 67
replace A_h = 7408 if strata == 68
replace A_h = 8588 if strata == 69
replace A_h = 10667 if strata == 70
replace A_h = 19810 if strata == 71
replace A_h = 6097 if strata == 72
replace A_h = 22405 if strata == 73
replace A_h = 8701 if strata == 74

* M_h average number of households per cluster by strata
gen M_h = 0
replace M_h = 225 if strata== 1
replace M_h = 855 if strata== 2
replace M_h = 180 if strata== 3
replace M_h = 855 if strata== 4
replace M_h = 225 if strata== 5
replace M_h = 855 if strata== 6
replace M_h = 90 if strata== 7
replace M_h = 990 if strata== 8
replace M_h = 270 if strata== 9
replace M_h = 765 if strata== 10
replace M_h = 405 if strata== 11
replace M_h = 675 if strata== 12
replace M_h = 270 if strata== 13
replace M_h = 765 if strata== 14
replace M_h = 225 if strata== 15
replace M_h = 810 if strata== 16
replace M_h = 135 if strata== 17
replace M_h = 945 if strata== 18
replace M_h = 675 if strata== 19
replace M_h = 1125 if strata== 20
replace M_h = 495 if strata== 21
replace M_h = 585 if strata== 22
replace M_h = 180 if strata== 23
replace M_h = 855 if strata== 24
replace M_h = 270 if strata== 25
replace M_h = 810 if strata== 26
replace M_h = 675 if strata== 27
replace M_h = 360 if strata== 28
replace M_h = 225 if strata== 29
replace M_h = 810 if strata== 30
replace M_h = 315 if strata== 31
replace M_h = 765 if strata== 32
replace M_h = 180 if strata== 33
replace M_h = 855 if strata== 34
replace M_h = 180 if strata== 35
replace M_h = 900 if strata== 36
replace M_h = 360 if strata== 37
replace M_h = 720 if strata== 38
replace M_h = 720 if strata== 39
replace M_h = 315 if strata== 40
replace M_h = 765 if strata== 41
replace M_h = 315 if strata== 42
replace M_h = 810 if strata== 43
replace M_h = 270 if strata== 44
replace M_h = 765 if strata== 45
replace M_h = 270 if strata== 46
replace M_h = 495 if strata== 47
replace M_h = 585 if strata== 48
replace M_h = 585 if strata== 49
replace M_h = 450 if strata== 50
replace M_h = 855 if strata== 51
replace M_h = 180 if strata== 52
replace M_h = 765 if strata== 53
replace M_h = 315 if strata== 54
replace M_h = 855 if strata== 55
replace M_h = 180 if strata== 56
replace M_h = 135 if strata== 57
replace M_h = 900 if strata== 58
replace M_h = 45 if strata== 59
replace M_h = 1035 if strata== 60
replace M_h = 270 if strata== 61
replace M_h = 765 if strata== 62
replace M_h = 495 if strata== 63
replace M_h = 585 if strata== 64
replace M_h = 495 if strata== 65
replace M_h = 585 if strata== 66
replace M_h = 270 if strata== 67
replace M_h = 765 if strata== 68
replace M_h = 495 if strata== 69
replace M_h = 585 if strata== 70
replace M_h = 1800 if strata== 71
replace M_h = 0 if strata== 72
replace M_h = 540 if strata== 73
replace M_h = 540 if strata== 74

* m_c total number of completed households (added from the HR dataset)
gen m_c= 40427
* M total number of households in country
gen M = 28900492
* S_h households selected per stratum
gen S_h = 45
gen DHSwt = perweight

**********************************************************************
* Stage B *** Approximate Level-weights ***
**********************************************************************
* Steps to approximate Level-1 and Level-2 weights from Household or Individual Weights
*Step 1. De-normalize the final weight, using approximated normalization factor
gen d_HH = DHSwt * (M/m_c)
*Step 2. Approximate the Level-2 weight
* f the variation factor
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
* Calculating the level-weights based on different values of alpha
scalar alpha = 0.5
gen wt2 = (A_h/a_c_h)*(f^alpha)
*** 3 ***************************
gen wt1 = d_HH/wt2

***Save
save ipums_2013, replace

restore

preserve
****************************************************************************
keep if year == 2008

gen survey = 2008

**********************************************************************
* Stage A *** Compile parameters/inputs for Level-weights calculations
**********************************************************************
* a_c_h completed clusters by strata
gen a_c_h=.
quietly levelsof strata, local(lstrata)
quietly foreach ls of local lstrata {
tab clusterno if strata==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if strata==`ls'
}

* A_h total number of census clusters by strata
gen A_h = 0
replace A_h = 2452 if strata == 1
replace A_h = 1138 if strata == 2
replace A_h = 2006 if strata == 3
replace A_h = 20850 if strata == 4
replace A_h = 5492 if strata == 5
replace A_h = 10354 if strata == 6
replace A_h = 11715 if strata == 7
replace A_h = 4556 if strata == 8
replace A_h = 2008 if strata == 9
replace A_h = 7211 if strata == 10
replace A_h = 5126 if strata == 11
replace A_h = 18319 if strata == 12
replace A_h = 3949 if strata == 13
replace A_h = 11930 if strata == 14
replace A_h = 2820 if strata == 15
replace A_h = 9988 if strata == 16
replace A_h = 2761 if strata == 17
replace A_h = 17124 if strata == 18
replace A_h = 7798 if strata == 19
replace A_h = 16288 if strata == 20
replace A_h = 1955 if strata == 21
replace A_h = 7539 if strata == 22
replace A_h = 1657 if strata == 23
replace A_h = 8943 if strata == 24
replace A_h = 3053 if strata == 25
replace A_h = 11870 if strata == 26
replace A_h = 2293 if strata == 27
replace A_h = 18900 if strata == 28
replace A_h = 9529 if strata == 29
replace A_h = 12263 if strata == 30
replace A_h = 16957 if strata == 31
replace A_h = 19402 if strata == 32
replace A_h = 6874 if strata == 33
replace A_h = 26442 if strata == 34
replace A_h = 2621 if strata == 35
replace A_h = 14020 if strata == 36
replace A_h = 2548 if strata == 37
replace A_h = 10231 if strata == 38
replace A_h = 3090 if strata == 39
replace A_h = 13942 if strata == 40
replace A_h = 2106 if strata == 41
replace A_h = 9463 if strata == 42
replace A_h = 18409 if strata == 43
replace A_h = 3498 if strata == 44
replace A_h = 11911 if strata == 45
replace A_h = 1977 if strata == 46
replace A_h = 9774 if strata == 47
replace A_h = 4223 if strata == 48
replace A_h = 10006 if strata == 49
replace A_h = 9567 if strata == 50
replace A_h = 908 if strata == 51
replace A_h = 16205 if strata == 52
replace A_h = 2628 if strata == 53
replace A_h = 6379 if strata == 54
replace A_h = 1410 if strata == 55
replace A_h = 14912 if strata == 56
replace A_h = 9008 if strata == 57
replace A_h = 9201 if strata == 58
replace A_h = 7964 if strata == 59
replace A_h = 4829 if strata == 60
replace A_h = 12480 if strata == 61
replace A_h = 12381 if strata == 62
replace A_h = 9438 if strata == 63
replace A_h = 2123 if strata == 64
replace A_h = 25424 if strata == 65
replace A_h = 0 if strata == 66
replace A_h = 7085 if strata == 67
replace A_h = 7408 if strata == 68
replace A_h = 8588 if strata == 69
replace A_h = 10667 if strata == 70
replace A_h = 19810 if strata == 71
replace A_h = 6097 if strata == 72
replace A_h = 22405 if strata == 73
replace A_h = 8701 if strata == 74

* M_h average number of households per cluster by strata
gen M_h = 0
replace M_h = 225 if strata== 1
replace M_h = 855 if strata== 2
replace M_h = 180 if strata== 3
replace M_h = 855 if strata== 4
replace M_h = 225 if strata== 5
replace M_h = 855 if strata== 6
replace M_h = 90 if strata== 7
replace M_h = 990 if strata== 8
replace M_h = 270 if strata== 9
replace M_h = 765 if strata== 10
replace M_h = 405 if strata== 11
replace M_h = 675 if strata== 12
replace M_h = 270 if strata== 13
replace M_h = 765 if strata== 14
replace M_h = 225 if strata== 15
replace M_h = 810 if strata== 16
replace M_h = 135 if strata== 17
replace M_h = 945 if strata== 18
replace M_h = 675 if strata== 19
replace M_h = 1125 if strata== 20
replace M_h = 495 if strata== 21
replace M_h = 585 if strata== 22
replace M_h = 180 if strata== 23
replace M_h = 855 if strata== 24
replace M_h = 270 if strata== 25
replace M_h = 810 if strata== 26
replace M_h = 675 if strata== 27
replace M_h = 360 if strata== 28
replace M_h = 225 if strata== 29
replace M_h = 810 if strata== 30
replace M_h = 315 if strata== 31
replace M_h = 765 if strata== 32
replace M_h = 180 if strata== 33
replace M_h = 855 if strata== 34
replace M_h = 180 if strata== 35
replace M_h = 900 if strata== 36
replace M_h = 360 if strata== 37
replace M_h = 720 if strata== 38
replace M_h = 720 if strata== 39
replace M_h = 315 if strata== 40
replace M_h = 765 if strata== 41
replace M_h = 315 if strata== 42
replace M_h = 810 if strata== 43
replace M_h = 270 if strata== 44
replace M_h = 765 if strata== 45
replace M_h = 270 if strata== 46
replace M_h = 495 if strata== 47
replace M_h = 585 if strata== 48
replace M_h = 585 if strata== 49
replace M_h = 450 if strata== 50
replace M_h = 855 if strata== 51
replace M_h = 180 if strata== 52
replace M_h = 765 if strata== 53
replace M_h = 315 if strata== 54
replace M_h = 855 if strata== 55
replace M_h = 180 if strata== 56
replace M_h = 135 if strata== 57
replace M_h = 900 if strata== 58
replace M_h = 45 if strata== 59
replace M_h = 1035 if strata== 60
replace M_h = 270 if strata== 61
replace M_h = 765 if strata== 62
replace M_h = 495 if strata== 63
replace M_h = 585 if strata== 64
replace M_h = 495 if strata== 65
replace M_h = 585 if strata== 66
replace M_h = 270 if strata== 67
replace M_h = 765 if strata== 68
replace M_h = 495 if strata== 69
replace M_h = 585 if strata== 70
replace M_h = 1800 if strata== 71
replace M_h = 0 if strata== 72
replace M_h = 540 if strata== 73
replace M_h = 540 if strata== 74

* m_c total number of completed households (added from the HR dataset)
gen m_c= 34070
* M total number of households in country
gen M = 28900492
* S_h households selected per stratum
gen S_h = 41
gen DHSwt = perweight

**********************************************************************
* Stage B *** Approximate Level-weights ***
**********************************************************************
* Steps to approximate Level-1 and Level-2 weights from Household or Individual Weights
*Step 1. De-normalize the final weight, using approximated normalization factor
gen d_HH = DHSwt * (M/m_c)
*Step 2. Approximate the Level-2 weight
* f the variation factor
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
* Calculating the level-weights based on different values of alpha
scalar alpha = 0.5
gen wt2 = (A_h/a_c_h)*(f^alpha)
*** 3 ***************************
gen wt1 = d_HH/wt2

***Save
save ipums_2008, replace

restore

***Append
use ipums_2008, clear
append using ipums_2013
append using ipums_2018
fre survey

**************************************************************
* SECTION 1:
**************************************************************
****Generating weight***** using the hiv-survey weight because hiv prevalence is the outcome of interest
gen wt = perweight
egen pooled_cluster = group(year clusterno), label
egen pooled_strata = group(year strata), label
svyset pooled_cluster [pweight=wt], strata(pooled_strata) singleunit(centered)

**Children ever born
fre cheb
recode cheb (0=0 "Childless")(1/18=1 "Non-childless")(else=.), gen(fertility)
fre fertility

**Age
fre age
clonevar aage = age

**Education
fre edyrtotal
clonevar edu = edyrtotal
replace edu =. if edyrtotal > 22
fre edu 

**Wealth quintiles
fre wealthq
clonevar wealth = wealthq
fre wealth

**Missing data exploration
egen nmiss = rowmiss(fertility aage edu wealth)
ta nmiss

**Target sample
gen pop = aage==15
ta pop
 
***Declare weight
svyset pooled_cluster [pweight=wt], strata(pooled_strata) singleunit(centered)

**OLS
svy,subpop(pop): reg fertility edu i.wealth
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) title("Table: Using svy,subpop") ctitle("OLS") replace 
**Poisson
svy,subpop(pop): poisson fertility edu i.wealth
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Poisson") append 
**Logistic
svy,subpop(pop): logistic fertility edu i.wealth 
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Logistic") append 

***Random Intercept model
**Decleare multilevel weight
svyset pooled_cluster, weight(wt2) strata(pooled_strata) ///
    singleunit(centered) || _n, weight(wt)

svy,subpop(pop): melogit fertility edu i.wealth || pooled_cluster:
outreg2 using "reg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Random Intercept Logistic") append 


***Testing SVYSLIM
*==================================================================*
* Across Countries in Africa: Single level models
*==================================================================*
preserve
svyset pooled_cluster [pweight=wt], strata(pooled_strata) singleunit(centered)   // declare survey data
**Keep variables
svyslim pop, complete(fertility edu wealth)       // shrinks to subpop
save subpop_slimy, replace                // 5,697 rows out of 114,154

* ---- FROM NOW ON (fast, small file) ----
use subpop_slimy, clear
**OLS
svy,subpop(pop): reg fertility edu i.wealth
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) title("Table: Using svyslim") ctitle("OLS") replace 
**Poisson
svy,subpop(pop): poisson fertility edu i.wealth
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Poisson") append 
**Logistic
svy,subpop(pop): logistic fertility edu i.wealth 
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N (subpop)", e(N_subpop)) dec(2) ctitle("Logistic") append 
restore

***Random Intercept model
preserve
**Decleare multilevel weight
svyset pooled_cluster, weight(wt2) strata(pooled_strata) ///
    singleunit(centered) || _n, weight(wt)
**Keep variables
svyslim pop, complete(fertility edu wealth) pweight(wt)       // shrinks to subpop
save subpop_slimmy, replace                // 5,697 rows out of 114,154
use subpop_slimmy, clear
***Random intercept regression
svy,subpop(pop): melogit fertility edu i.wealth || pooled_cluster:
outreg2 using "regg.doc", stats(coef ci) noobs addstat("Prob > F", e(p), "N *(subpop)", e(N_subpop)) dec(2) ctitle("Random Intercept Logistic") append 
restore
