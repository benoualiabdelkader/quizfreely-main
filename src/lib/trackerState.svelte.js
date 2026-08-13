export const DEFAULT_TENSES = [
    { id: 'past-simple', name: 'Past Simple', description: 'Completed actions in past' },
    { id: 'past-continuous', name: 'Past Continuous', description: 'Ongoing actions in the past' },
    { id: 'past-perfect', name: 'Past Perfect', description: 'Actions completed before another past action' },
    { id: 'present-simple', name: 'Present Simple', description: 'Facts, habits, and general truths' },
    { id: 'present-continuous', name: 'Present Continuous', description: 'Ongoing actions happening now' },
    { id: 'present-perfect', name: 'Present Perfect', description: 'Past actions with present consequences' },
    { id: 'future-simple', name: 'Future Simple', description: 'Promises, predictions, or spontaneous decisions' },
];

export const CHECKLIST_STEPS = [
    { id: 'grammar', label: 'Grammar' },
    { id: 'vocabulary', label: 'Vocabulary' },
    { id: 'quizfreely', label: 'Quizfreely' },
    { id: 'reading', label: 'Reading' },
    { id: 'listening', label: 'Listening' },
    { id: 'writing', label: 'Writing' },
    { id: 'speaking', label: 'Speaking' },
    { id: 'massiveExercises', label: 'Massive Exercises' },
    { id: 'errorReview', label: 'Error Review' },
    { id: 'checkpoint', label: 'Checkpoint' }
];

export function createTrackerState() {
    let tensesData = $state({});
    let roundsData = $state({});
    let loaded = $state(false);

    function init() {
        if (loaded) return;
        if (typeof window !== 'undefined' && typeof localStorage !== 'undefined') {
            const storedTenses = localStorage.getItem('wave01_tenses');
            const storedRounds = localStorage.getItem('wave01_rounds');
            
            if (storedTenses) {
                try { tensesData = JSON.parse(storedTenses); } catch (e) {}
            } else {
                const initialTenses = {};
                DEFAULT_TENSES.forEach(t => {
                    initialTenses[t.id] = { ...t, roundIds: [] };
                });
                tensesData = initialTenses;
            }

            if (storedRounds) {
                try { roundsData = JSON.parse(storedRounds); } catch (e) {}
            }
        }
        loaded = true;
    }

    function save() {
        if (!loaded || typeof window === 'undefined' || typeof localStorage === 'undefined') return;
        localStorage.setItem('wave01_tenses', JSON.stringify(tensesData));
        localStorage.setItem('wave01_rounds', JSON.stringify(roundsData));
    }

    function createRound(tenseId, name, description, vocabularyInfo) {
        const roundId = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).substring(2, 15);
        
        const checklist = {};
        CHECKLIST_STEPS.forEach(step => {
            checklist[step.id] = false;
        });

        roundsData[roundId] = {
            id: roundId,
            tenseId,
            name,
            description,
            vocabularyInfo,
            checklist,
            createdAt: Date.now()
        };

        if (!tensesData[tenseId]) {
            tensesData[tenseId] = { id: tenseId, name: tenseId, description: '', roundIds: [] };
        }
        tensesData[tenseId].roundIds.push(roundId);
        save();
        return roundId;
    }

    function toggleChecklistStep(roundId, stepId) {
        if (roundsData[roundId]) {
            roundsData[roundId].checklist[stepId] = !roundsData[roundId].checklist[stepId];
            save();
        }
    }
    
    function getRoundProgress(roundId) {
        const round = roundsData[roundId];
        if (!round) return { completed: 0, total: 10, percent: 0, status: 'NOT STARTED' };
        
        let completed = 0;
        for (const step of CHECKLIST_STEPS) {
            if (round.checklist[step.id]) completed++;
        }
        
        const percent = Math.round((completed / 10) * 100);
        let status = 'IN PROGRESS';
        if (completed === 0) status = 'NOT STARTED';
        if (completed === 10) status = 'COMPLETED';
        
        return { completed, total: 10, percent, status };
    }

    function getTenseProgress(tenseId) {
        const tense = tensesData[tenseId];
        if (!tense || !tense.roundIds || tense.roundIds.length === 0) {
            return { completedRounds: 0, totalRounds: 0, percent: 0 };
        }
        
        let totalPercent = 0;
        let completedRounds = 0;
        
        tense.roundIds.forEach(id => {
            const p = getRoundProgress(id);
            totalPercent += p.percent;
            if (p.status === 'COMPLETED') completedRounds++;
        });
        
        const avgPercent = Math.round(totalPercent / tense.roundIds.length);
        return { 
            completedRounds, 
            totalRounds: tense.roundIds.length, 
            percent: avgPercent 
        };
    }

    return {
        get loaded() { return loaded; },
        get tenses() { return tensesData; },
        get rounds() { return roundsData; },
        init,
        save,
        createRound,
        toggleChecklistStep,
        getRoundProgress,
        getTenseProgress
    };
}

export const trackerState = createTrackerState();
