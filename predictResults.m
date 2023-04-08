function predictions = predictResults(schedule_table_name, teams, start_date, cutoff_date)
    % Connect to MySQL database
    conn = database('elo_nba', 'root', '', 'com.mysql.jdbc.Driver', 'jdbc:mysql://localhost:3306/elo_nba');
    
    % Convert start_date and cutoff_date to datetime
    start_date = datetime(start_date, 'InputFormat', 'M dd yyyy');
    cutoff_date = datetime(cutoff_date, 'InputFormat', 'M dd yyyy');
    
    % Get game data from schedule table
    data = select(conn,['SELECT Visitor, Home, Date FROM ' schedule_table_name]);
    
    % Convert Date column to datetime
    data.Date = datetime(regexprep(data.Date,'^\w{3}\s',''), 'InputFormat', 'MMM dd yyyy');
    
    % Filter data by start_date and cutoff_date
    data = data(data.Date >= start_date & data.Date <= cutoff_date,:);
    
    % Initialize predictions table
    predictions = table();
    predictions.Visitor = data.Visitor;
    predictions.Home = data.Home;
    predictions.PredictedWinner = cell(height(data), 1);
    
    % Predict winner for each game
    for i = 1:height(data)
        visitor = data.Visitor{i};
        home = data.Home{i};
        
        visitor_elo = teams.ELO_Rating(strcmp(teams.Name, visitor));
        home_elo = teams.ELO_Rating(strcmp(teams.Name, home));
        
        % Calculate expected win rates
        expected_visitor = 1 / (1 + 10^((home_elo - visitor_elo) / 400));
        expected_home = 1 - expected_visitor;
        
        % Predict winner
        if expected_visitor > expected_home
            predictions.PredictedWinner{i} = visitor;
        else
            predictions.PredictedWinner{i} = home;
        end
    end
    
    % Close database connection
    close(conn);
end