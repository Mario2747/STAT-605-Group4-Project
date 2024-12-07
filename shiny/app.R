library(shiny)
library(xgboost)
library(data.table)

# Define the UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color: #FFF9F0;
        color: #4F2C1D;
        font-family: 'Arial', sans-serif;
        margin: 0;
        padding: 0;
      }
      .container {
        max-width: 1400px;
        margin: 0 auto;
        padding: 20px;
      }
      .card {
        background: #FFFFFF;
        box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.1);
        border-radius: 10px;
        padding: 20px;
        margin-bottom: 20px;
      }
      .btn {
        background-color: #FFBD59;
        border-color: #FF9A34;
        color: #4F2C1D;
        font-weight: bold;
      }
      .btn:hover {
        background-color: #FF9A34;
        border-color: #FF7A00;
      }
      h1 {
        text-align: center;
        font-weight: bold;
      }
      h3 {
          text-align: left;
          font-size: 18px;
          font-weight: bold;
      }
      h4 {
          text-align: center;
          font-size: 18px;
          font-weight: bold;
      }
      .title-panel {
        background-color: #FFE8C2;
        padding: 20px;
        border-radius: 10px;
        margin-bottom: 20px;
        text-align: center;
      }
      .output-box {
        background: #FFF4E6;
        border-radius: 10px;
        padding: 15px;
        margin-top: 20px;
      }
      #offense_name, #probability {
        font-size: 16px;
        color: #4F2C1D;
      }
      .footer {
          background-color: #FFE8C2;
          padding: 10px 20px;
          border-radius: 10px;
          text-align: left;
          font-size: 14px;
          color: #4F2C1D;
          margin-top: 20px;
      }
      .footer p {
          margin: 0;
          line-height: 1.5;
      }
    "))
  ),
  
  div(class = "container",
      div(class = "title-panel",
          h1("Trip Crime Prediction Tool"),
          h4("STAT605 Group3 4")
      ),
      
      div(class = "card",
          sidebarLayout(
            sidebarPanel(
              h3("Enter your travel and personal information:"),
              fluidRow(
                column(6,
                       selectInput("state_name", "State Name(First Choose):", choices = c(
                         "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", 
                         "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", 
                         "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", 
                         "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", 
                         "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
                       )),
                       selectInput("county_name", "County Name:", choices = NULL),
                       numericInput("incident_hour", "Trip Time:", value = 0, min = 0, max = 23),
                       numericInput("age_num", "Age:", value = 74, min = 0),
                       selectInput("sex_code", "Gender:", choices = c("M", "F", "U", "X"), selected = "M"),
                       selectInput("incident_date_month", "Month:", choices = sprintf("%02d", 1:12), selected = "01")
                ),
                column(6,
                       selectInput("location_name", "Location Name:", choices = NULL),
                       selectInput("victim_type_name", "Trip Type:", choices = NULL),
                       selectInput("race_desc", "Race:", choices = NULL),
                       selectInput("incident_date_dayofweek", "Day of the Week:", choices = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"), selected = "Wednesday"),
                       selectInput("time_of_day", "Time of Day:", choices = c("day", "night"), selected = "night")
                )
              ),
              actionButton("predict", "Predict", class = "btn btn-lg btn-block"),
              width = 7
            ),
            
            mainPanel(
              h3("Prediction Results"),
              div(class = "output-box",
                  h3("Types of Crime Name you may encounter:"),
                  textOutput("offense_name"),
                  h3("Probability (the likelihood of experiencing the above-mentioned types of crime):"),
                  textOutput("probability"),
                  h3("Notice:"),
                  p("Please stay vigilant and take necessary precautions based on the potential crime type. We wish you a safe and enjoyable trip.")
              ),
              width = 5
            )
          )
      ),
      div(class = "footer", 
          HTML("
            <p><strong>Contact Information</strong><br>
            <strong>Contact app maintainer:</strong> zchen2353@wisc.edu<br>
            <strong>Contributor:</strong> Mario MA, YITENG TU, YUCHEN XU, YUDI WANG, ZHENGYONG CHEN</p>
        ")
      )
  )
)

# Define the server function
server <- function(input, output, session) {
  crime_types <- NULL
  locations <- NULL
  victim_types <- NULL
  races <- NULL
  agencies <- NULL
  model <- NULL
  
  # Preload the models when the app starts
  observe({
    crime_types <<- tryCatch(read.csv('NIBRS_OFFENSE_TYPE.csv'), error = function(e) NULL)
    locations <<- tryCatch(read.csv('NIBRS_LOCATION_TYPE.csv'), error = function(e) NULL)
    victim_types <<- tryCatch(read.csv('NIBRS_VICTIM_TYPE.csv'), error = function(e) NULL)
    races <<- tryCatch(read.csv('REF_RACE.csv'), error = function(e) NULL)
    
    # Load initial data for the first state (AZ) to populate the county dropdown
    agencies <<- tryCatch(read.csv('AZagencies.csv'), error = function(e) NULL)
    
    # Check if all the data files are loaded correctly
    if (any(sapply(list(crime_types, locations, victim_types, races, agencies), is.null))) {
      showModal(modalDialog(
        title = "Error",
        "One or more data files could not be loaded. Please check your files.",
        easyClose = TRUE,
        footer = NULL
      ))
      return()
    }
    
    # Initialize selectInput choices based on the loaded data
    updateSelectInput(session, "county_name", choices = agencies$county_name)
    updateSelectInput(session, "location_name", choices = locations$location_name)
    updateSelectInput(session, "victim_type_name", choices = victim_types$victim_type_name)
    updateSelectInput(session, "race_desc", choices = races$race_desc)
  })
  
  observeEvent(input$state_name, {
    # Dynamically load the corresponding agencies file based on state selection
    agencies_file <- paste0(input$state_name, "agencies.csv")
    agencies <<- tryCatch(read.csv(agencies_file), error = function(e) NULL)
    
    # Check if the file is loaded correctly
    if (is.null(agencies)) {
      showModal(modalDialog(
        title = "Error",
        paste("Could not load", agencies_file, "Please check the file."),
        easyClose = TRUE,
        footer = NULL
      ))
      return()
    }
    
    # Update the county_name dropdown with the counties from the selected state's file
    updateSelectInput(session, "county_name", choices = agencies$county_name)
  })
  
  observeEvent(input$predict, {
    # Check if a model is loaded
    model_filename <- paste0(input$state_name, "xgb-model.bin")
    model <- tryCatch(xgboost::xgb.load(model_filename), error = function(e) NULL)
    model <<- model
    
    crime_types <<- read.csv('NIBRS_OFFENSE_TYPE.csv')
    locations <<- read.csv('NIBRS_LOCATION_TYPE.csv')
    victim_types <<- read.csv('NIBRS_VICTIM_TYPE.csv')
    races <<- read.csv('REF_RACE.csv')
    agencies <<- read.csv('AKagencies.csv')
    
    if (is.null(model)) {
      showModal(modalDialog(
        title = "Error",
        "Model could not be loaded. Please check the model file.",
        easyClose = TRUE,
        footer = NULL
      ))
      return()
    }
    
    # 打印所有输入值
    print(input$county_name)
    print(input$location_name)
    print(input$age_num)
    print(input$incident_hour)
    print(input$incident_date_month)
    
    # 校验选择的ID
    selected_location_id <- ifelse(input$location_name %in% locations$location_name,
                                   locations$location_id[locations$location_name == input$location_name],
                                   NA)
    selected_victim_type_id <- ifelse(input$victim_type_name %in% victim_types$victim_type_name,
                                      victim_types$victim_type_id[victim_types$victim_type_name == input$victim_type_name],
                                      NA)
    selected_race_id <- ifelse(input$race_desc %in% races$race_desc,
                               races$race_id[races$race_desc == input$race_desc],
                               NA)
    selected_agency_id <- ifelse(input$county_name %in% agencies$county_name,
                                 agencies$agency_id[agencies$county_name == input$county_name],
                                 NA)
    
    # 如果有选择无效，显示错误弹窗
    if (any(is.na(c(selected_location_id, selected_victim_type_id, selected_race_id)))) {
      showModal(modalDialog(
        title = "Error",
        "Invalid location, victim type, or race selection. Please verify your choices.",
        easyClose = TRUE,
        footer = NULL
      ))
      return()
    }
    
    formatted_month <- sprintf("%02d", as.numeric(input$incident_date_month))
    
    
    # 准备输入数据
    input_data <- data.frame(
      agency_id = ifelse(is.na(as.numeric(selected_agency_id)),0,as.numeric(selected_agency_id)),
      location_id = as.numeric(selected_location_id),
      incident_hour = as.numeric(input$incident_hour),
      victim_type_id = as.numeric(selected_victim_type_id),
      age_num = as.numeric(input$age_num),
      sex_code = factor(input$sex_code, levels = c("M", "F", "U", "X")),
      race_id = as.numeric(selected_race_id),
      incident_date_month = as.numeric(formatted_month),
      incident_date_dayofweek = factor(input$incident_date_dayofweek, 
                                       levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")),
      time_of_day = factor(input$time_of_day, levels = c("day", "night"))
      
    )
    
    # 打印输入数据，检查是否发生变化
    print("Input data:")
    print(input_data)
    
    input_data<<-input_data
    
    dmatrix <- xgb.DMatrix(data = model.matrix(~ . - 1, data = input_data))
    
    
    # 执行预测
    raw_prediction <- predict(model, dmatrix, type = "prob")
    max_probability <- max(raw_prediction)
    predicted_index <- which.max(raw_prediction)
    
    # 映射到实际的犯罪代码和名称
    predicted_code <- crime_types$offense_code[predicted_index]
    predicted_name <- crime_types$offense_name[predicted_index]
    
    # 打印原始预测结果
    print("Raw prediction result:")
    print(raw_prediction)
    
    # 将预测结果传递到UI
    output$offense_name <- renderText({ predicted_name })
    output$probability <- renderText({
      result <- max_probability * 0.003
      sprintf(" %.2f%%", result * 100)
    })
    
  })
}



# Run the application
shinyApp(ui = ui, server = server)

