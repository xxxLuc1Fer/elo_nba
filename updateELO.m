function teams = updateELO(schedule_table_name, teams, cutoff_date)
    % Connect to MySQL database
    conn = database('elo_nba', 'root', '', 'com.mysql.jdbc.Driver', 'jdbc:mysql://localhost:3306/elo_nba');
    
    % Convert cutoff_date to datetime
    cutoff_date = datetime(cutoff_date, 'InputFormat', 'M dd yyyy');
    
    % Get game data from schedule table
    data = select(conn,['SELECT Visitor, VisitorPTS, Home, HomePTS, Date FROM ' schedule_table_name]);
    
    % Convert Date column to datetime
    data.Date = datetime(regexprep(data.Date,'^\w{3}\s',''), 'InputFormat', 'MMM dd yyyy');
    
    % Filter data by cutoff_date
    data = data(data.Date <= cutoff_date,:);
    
    % Determine if it is early in the season
    early_season_start = datetime('2022-10-01', 'InputFormat', 'yyyy-MM-dd');
    early_season_end = datetime('2022-11-30', 'InputFormat', 'yyyy-MM-dd');
    early_season = cutoff_date >= early_season_start & cutoff_date <= early_season_end;
    
    % Calculate ELO change for each game
    for i = 1:height(data)
        visitor = data.Visitor{i};
        home = data.Home{i};
        
        visitor_elo = teams.ELO_Rating(strcmp(teams.Name, visitor));
        home_elo = teams.ELO_Rating(strcmp(teams.Name, home));
        
        % Calculate expected win rates
        expected_visitor = 1 / (1 + 10^((home_elo - visitor_elo) / 400));
        expected_home = 1 - expected_visitor;
        
        % Calculate actual win rates and update wins and losses
        if data.VisitorPTS(i) > data.HomePTS(i)
            actual_visitor = 1;
            actual_home = 0;
            teams.Wins(strcmp(teams.Name, visitor)) = teams.Wins(strcmp(teams.Name, visitor)) + 1;
            teams.Losses(strcmp(teams.Name, home)) = teams.Losses(strcmp(teams.Name, home)) + 1;
        else
            actual_visitor = 0;
            actual_home = 1;
            teams.Wins(strcmp(teams.Name, home)) = teams.Wins(strcmp(teams.Name, home)) + 1;
            teams.Losses(strcmp(teams.Name, visitor)) = teams.Losses(strcmp(teams.Name, visitor)) + 1;
        end
        
        % Adjust k value based on winner's ELO rating and whether it is early in the season
        if early_season
            k = 40;
        else
            winner_elo = max(visitor_elo, home_elo);
            if winner_elo < 1600
                k = 32;
            elseif winner_elo < 1700
                k = 24;
            else
                k = 16;
            end
        end
        
        % Calculate ELO change
        delta_visitor = k * (actual_visitor - expected_visitor);
        delta_home = k * (actual_home - expected_home);
                      
        % Add upset bonus if the winner's ELO rating is significantly lower than the loser's
        upset_coefficient = 0.1; % Coefficient for calculating upset bonus
        upset_threshold = 100; % ELO rating difference threshold for upset bonus
        if actual_visitor == 1 && visitor_elo < home_elo - upset_threshold
            delta_visitor = delta_visitor + upset_coefficient * (home_elo - visitor_elo);
        elseif actual_home == 1 && home_elo < visitor_elo - upset_threshold
            delta_home = delta_home + upset_coefficient * (visitor_elo - home_elo);
        end
        
        % Add away win bonus if visitor team wins and teams are evenly matched or visitor team is weaker
        away_win_bonus = 7.5;
        if actual_visitor == 1 && visitor_elo < home_elo + upset_threshold
            delta_visitor = delta_visitor + away_win_bonus;
        end
        
        % Update ELO ratings
        teams.ELO_Rating(strcmp(teams.Name, visitor)) = visitor_elo + delta_visitor;
        teams.ELO_Rating(strcmp(teams.Name, home)) = home_elo + delta_home;
    end
    
    % Close database connection
    close(conn);
end