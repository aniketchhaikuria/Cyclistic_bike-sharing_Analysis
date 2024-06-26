# Installing packages
install.packages("tidyverse")
install.packages("ggplot2")
install.packages("dplyr")
install.packages("lubridate")

# Loading required libraries
library(tidyverse)
library(ggplot2)
library(dplyr)
library(lubridate)
library(conflicted)

# Avoid conflicts in function names
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

# Read data files for Q1 of 2019 and 2020
q1_2019 <- read_csv("Divvy_Trips_2019_Q1.csv")
q1_2020 <- read_csv("Divvy_Trips_2020_Q1.csv")

# Check column names of the datasets
colnames(q1_2019)
colnames(q1_2020)

# Rename columns of q1_2019 dataset
q1_2019 <- rename(q1_2019,
                  ride_id = trip_id,
                  rideable_type = bikeid,
                  started_at = start_time,
                  ended_at = end_time,
                  start_station_name = from_station_name,
                  start_station_id = from_station_id,
                  end_station_name = to_station_name,
                  end_station_id = to_station_id,
                  member_casual = usertype
)

# Display structure of q1_2019 and q1_2020 datasets
str(q1_2019)
str(q1_2020)

# Convert ride_id and rideable_type columns to character in q1_2019 dataset
q1_2019 <- mutate(q1_2019, ride_id = as.character(ride_id),
                  rideable_type = as.character(rideable_type))

# Combine datasets q1_2019 and q1_2020
all_trips <- bind_rows(q1_2019, q1_2020)

# Remove unnecessary columns
all_trips <- all_trips %>%
  select(-c(start_lat, start_lng, end_lat, end_lng, birthyear, gender, "tripduration"))

# Check column names, number of rows, dimensions, and top rows of the combined dataset
colnames(all_trips)
nrow(all_trips)
dim(all_trips)
head(all_trips)
str(all_trips)
summary(all_trips)

# Count occurrences of each member type
table(all_trips$member_casual)

# Recode member_casual column to have consistent values
all_trips <- all_trips %>%
  mutate(member_casual = recode(member_casual,
                                "Subscriber" = "member",
                                "Customer" = "casual"))

# Recheck occurrences of each member type
table(all_trips$member_casual)

# Extract date, month, day, year, and day_of_week from started_at column
all_trips$date <- as.Date(all_trips$started_at)
all_trips$month <- format(as.Date(all_trips$date), "%m")
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")

# Calculate ride_length
all_trips$ride_length <- difftime(all_trips$ended_at, all_trips$started_at)

# Convert ride_length to numeric
all_trips$ride_length <- as.numeric(as.character(all_trips$ride_length))

# Check ride_length variable type
is.numeric(all_trips$ride_length)

# Filter out rows with start_station_name as "HQ QR" or ride_length less than 0
all_trips_v2 <- all_trips[!(all_trips$start_station_name == "HQ QR" | all_trips$ride_length < 0),]

# Calculate mean, median, max, min, and summary statistics of ride_length
mean(all_trips_v2$ride_length)
median(all_trips_v2$ride_length)
max(all_trips_v2$ride_length)
min(all_trips_v2$ride_length)
summary(all_trips_v2$ride_length)

# Aggregate ride_length by member_casual
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = mean)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = median)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = max)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = min)

# Aggregate ride_length by member_casual and day_of_week
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week,
          FUN = mean)

# Order day_of_week variable
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week,
                                    levels = c("Sunday", "Monday",
                                               "Tuesday", "Wednesday",
                                               "Thursday", "Friday", "Saturday"))

# Aggregate ride_length by member_casual and day_of_week after ordering day_of_week
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week,
          FUN = mean)

# Group by member_casual and weekday, summarise number_of_rides and average_duration, and arrange data
all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n(),
            average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)

# Visualize number_of_rides by weekday and member_casual
all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>%
  group_by(member_casual, weekday) %>%
  summarise(number_of_rides = n(),
            average_duration = mean(ride_length)) %>%
  arrange(member_casual, weekday) %>%
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(x = "Weekday", y = "Number of Rides", title = "Ride Frequency by Weekday and User Type") +
  theme_minimal()

# Visualize average_duration by weekday and member_casual
all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>%
  group_by(member_casual, weekday) %>%
  summarise(number_of_rides = n(),
            average_duration = mean(ride_length)) %>%
  arrange(member_casual, weekday) %>%
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge") + 
  labs(x = "Weekday", y = "Average Ride Duration (minutes)", title = "Average Ride Duration by Weekday and User Type") +
  theme_minimal()

# Aggregate ride_length by member_casual and day_of_week, calculate mean, and save to csv
counts <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual +
                      all_trips_v2$day_of_week, FUN = mean)
write.csv(counts, file = 'avg_ride_length.csv')

# Visualization 1: Bar plot for comparison of ride duration between user types
ride_data <- data.frame(
  user_type = c("Annual Member", "Casual Rider"),
  avg_duration = c(25, 35) # Replace with actual average ride durations
)

ggplot(ride_data, aes(x = user_type, y = avg_duration, fill = user_type)) +
  geom_bar(stat = "identity") +
  labs(x = "User Type", y = "Average Ride Duration (minutes)", title = "Comparison of Ride Duration between Annual Members and Casual Riders") +
  theme_minimal()

# Visualization 2: Bar plot for comparison of ride frequency between user types by weekday
ride_data <- data.frame(
  weekday = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
  annual_members = c(100, 120, 110, 90, 130, 150, 140), # Replace with actual ride frequencies for annual members
  casual_riders = c(80, 90, 85, 70, 100, 110, 120) # Replace with actual ride frequencies for casual riders
)

ride_data_long <- tidyr::gather(ride_data, key = "user_type", value = "ride_frequency", -weekday)

ggplot(ride_data_long, aes(x = weekday, y = ride_frequency, fill = user_type)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(x = "Weekday", y = "Number of Rides", title = "Comparison of Ride Frequency between Annual Members and Casual Riders") +
  theme_minimal() +
  scale_fill_manual(values = c("Annual Member" = "blue", "Casual Rider" = "red")) # Customize colors as needed

#Exporting data for further analysis
counts <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual +
                      all_trips_v2$day_of_week, FUN = mean)
write.csv(counts, file = 'avg_ride_length.csv')