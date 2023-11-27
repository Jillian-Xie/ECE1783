function currentQP = getCurrentQP(QPs, statistics, budget)
currentQP = -1;
for i=1:length(statistics)
    if statistics(i) <= budget
        currentQP = QPs(i);
        break;
    end
end
if currentQP < 0
    currentQP = QPs(length(QPs));
end
end