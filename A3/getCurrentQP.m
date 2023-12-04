function [currentQP, currentQPIndex] = getCurrentQP(QPs, statistics, budget)
currentQP = -1;
for i=1:length(statistics)
    if statistics(i) <= budget
        currentQP = QPs(i);
        currentQPIndex = i;
        break;
    end
end
if currentQP < 0
    currentQP = QPs(length(QPs));
    currentQPIndex = length(QPs);
end
end