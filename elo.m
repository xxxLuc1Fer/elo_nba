clc,clear;
% Set up the database connection
conn = database('elo_nba', 'root', '', 'com.mysql.jdbc.Driver', 'jdbc:mysql://localhost:3306/elo_nba');

% Import the team table
teams = select(conn,'SELECT * FROM teams');

%The data for the matches played was collected from October 18th, 2022 to March 26th, 2023.
%The data for the matches not played was collected from March 27th, 2023 to April 9th, 2023.
start_date = '3 27 2023';
cutoff_date = '4 9 2023';

%Update ELO ratings
teams = updateELO('Games', teams, '3 26 2023');

predictions = predictResults('Schedule', teams, start_date, cutoff_date);
teams = updateWinsLosses(predictions, teams);
teams = sortrows(teams, 'Wins', 'descend')

% Split teams table into East and West
east_teams = teams(strcmp(teams.Conference, 'East'), :);
west_teams = teams(strcmp(teams.Conference, 'West'), :);

% Sort teams by wins in descending order
east_teams = sortrows(east_teams, 'Wins', 'descend')
west_teams = sortrows(west_teams, 'Wins', 'descend')