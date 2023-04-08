function teams = updateWinsLosses(predictions, teams)
    % Update wins and losses based on predictions
    for i = 1:height(predictions)
        visitor = predictions.Visitor{i};
        home = predictions.Home{i};
        predicted_winner = predictions.PredictedWinner{i};
        
        if strcmp(predicted_winner, visitor)
            teams.Wins(strcmp(teams.Name, visitor)) = teams.Wins(strcmp(teams.Name, visitor)) + 1;
            teams.Losses(strcmp(teams.Name, home)) = teams.Losses(strcmp(teams.Name, home)) + 1;
        else
            teams.Wins(strcmp(teams.Name, home)) = teams.Wins(strcmp(teams.Name, home)) + 1;
            teams.Losses(strcmp(teams.Name, visitor)) = teams.Losses(strcmp(teams.Name, visitor)) + 1;
        end
    end
end