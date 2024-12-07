# STAT-605-Project：Crime Prediction
Yuchen Xu, Mario Ma, Yiteng Tu, Yudi Wang, Zhengyong Chen.

## Description
This repository contains the code and resources for the data cleaning and preprocessing tasks related to the STAT-605 Group 4 project. The focus is on extracting, cleaning, and integrating data from various sources while optimizing parallel processing.
This project leverages crime data from the NIBRS dataset to analyze patterns and provide insights for enhancing public safety. The analysis focuses on understanding crime trends across different locations, times, and categories. The outcomes can help individuals, law enforcement, and policymakers make informed decisions to improve safety and allocate resources effectively.  
[Data origin](https://cde.ucr.cjis.gov/LATEST/webapp/#/pages/downloads)

## Repository Structure

### 1. Proposal
  - Descriptions of the variables, statistical methods, and computational steps we will consider to use.
    
### 2. Data cleaning
  - **generate_states_queue.sh**：
    - Shell script to generate a queue for state-based data processing.
  - **get_data.sh**：
    - Script to extract and download raw data files for processing.
  - **precleandata.sh**：
    - Script to clean and preprocess the raw data files.
  - **process_data1_(year).sub**:
    - HTCondor submission script for processing different year's data.
  - **process_data_fast1.R**:
    - R script for efficient data processing using data.table and other optimization methods.
  - **process_data_fast1.sh**:
    - Shell script to execute the process_data_fast1.R script.
  - **states_queue.txt**:
    - Text file containing a list of states to process.
Final cleaned data can be found at [Crime Clean Data](https://www.dropbox.com/scl/fi/6afvjxidwwymdnq5fdev9/clean_data.zip?rlkey=zpse953136c0olidoe3ixelc6&st=nfsg6zg3&dl=0).  
The reference of some columns in cleaned data can be found at [Reference Files](https://www.dropbox.com/scl/fi/4hditppd22t3p91w0l2b3/data_reference.zip?rlkey=gyiz3uh7b5hhzi2apxyezq8q8&st=l9gyk2xq&dl=0)
 
### 3. Model
  - **model.R**:  
    - Rscript containing training and testing XGBoost model. The data used can be found at the end of the second part.
  - **model.sh**:  
    - The .sh file used to run model.R on linux system.
  - **model.sub**:  
    - The .sub file used to submit the job on CHTC.
  - **states_queue.txt**:  
    - The list used in model.sub file to do the parallel jobs. It contains 50 states of America.
  - **WIxgb-model.bin**:  
    - An example final model(Wisconsin).
  - **WI-importance.csv**:  
    - The important factors of model(Wisconsin).
  - **WI-prediction.csv**:  
    - The final predictions on test set of model(Wisconsin).
  - **WI-scores.csv**:  
    - The precision, recall and F1-score of model(Wisconsin).       

### 4. EDA
- This document describes the exploratory data analysis (EDA) performed on the crime dataset to understand patterns, trends, and distributions of incidents across various states in the U.S. The EDA involves data visualization and summarization techniques to extract meaningful insights and guide subsequent data preprocessing and modeling steps.

### 5. Shiny Link
The Shiny app allows users to interactively . You can access the live app here:
- [Shiny App Link](https://andrewchanshiny.shinyapps.io/Trip_Crime_Prediction_Tool/)
