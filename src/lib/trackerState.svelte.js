import { db } from "$lib/idb-api-layer/db.js";

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
    { id: 'grammar', label: 'Grammar', desc: 'Understand the target grammar' },
    { id: 'vocabulary', label: 'Vocabulary', desc: 'Master this round\'s vocabulary' },
    { id: 'quizfreely', label: 'Quizfreely', desc: 'Active recall and drilling' },
    { id: 'reading', label: 'Reading', desc: 'Contextual understanding' },
    { id: 'listening', label: 'Listening', desc: 'Audio comprehension' },
    { id: 'writing', label: 'Writing', desc: 'Produce grammar independently' },
    { id: 'speaking', label: 'Speaking', desc: 'Produce grammar naturally' },
    { id: 'massiveExercises', label: 'Massive Exercises', desc: 'Intensive pattern drilling' },
    { id: 'errorReview', label: 'Error Review', desc: 'Turn mistakes into learning' },
    { id: 'checkpoint', label: 'Checkpoint', desc: 'Final mission evaluation' }
];

export function createTrackerState() {
    let tensesData = $state({});
    let roundsData = $state({});
    let loaded = $state(false);

    async function init() {
        if (loaded) return;
        
        if (typeof window === 'undefined') {
            loaded = true;
            return;
        }

        try {
            const dbTenses = await db.waveTenses.toArray();
            const dbRounds = await db.waveRounds.toArray();

            // Migration from localStorage
            if (dbTenses.length === 0 && dbRounds.length === 0) {
                const storedTenses = localStorage.getItem('wave01_tenses_v2');
                const storedRounds = localStorage.getItem('wave01_rounds_v2');
                
                if (storedTenses || storedRounds) {
                    if (storedTenses) {
                        const parsed = JSON.parse(storedTenses);
                        for (const tense of Object.values(parsed)) {
                            await db.waveTenses.put(tense);
                        }
                    }
                    if (storedRounds) {
                        const parsed = JSON.parse(storedRounds);
                        for (const round of Object.values(parsed)) {
                            await db.waveRounds.put(round);
                        }
                    }
                    localStorage.removeItem('wave01_tenses_v2');
                    localStorage.removeItem('wave01_rounds_v2');
                } else {
                    // Initialize empty defaults
                    const initialTenses = {};
                    for (const t of DEFAULT_TENSES) {
                        const tense = { ...t, roundIds: [] };
                        await db.waveTenses.put(tense);
                    }
                }
            }

            // Load into state
            const finalTenses = await db.waveTenses.toArray();
            const finalRounds = await db.waveRounds.toArray();
            
            const tState = {};
            for (const t of finalTenses) tState[t.id] = t;
            tensesData = tState;

            const rState = {};
            for (const r of finalRounds) rState[r.id] = r;
            roundsData = rState;

        } catch (error) {
            console.error("Failed to initialize tracker IDB:", error);
        }

        loaded = true;
    }

    // Keep save() synchronous-looking for the UI bindings, but run async ops inside
    function save() {
        if (!loaded || typeof window === 'undefined') return;
        
        // This is a generic save for when bindings trigger save()
        // It's better to use updateRoundState for precise updates, 
        // but we keep this for backwards compatibility with the existing UI bindings.
        // We will just iterate and save everything, though in a real app you'd proxy individual saves.
        for (const t of Object.values(tensesData)) {
            db.waveTenses.put($state.snapshot(t));
        }
        for (const r of Object.values(roundsData)) {
            db.waveRounds.put($state.snapshot(r));
        }
    }

    async function createRound(tenseId, name, description, vocabularyInfo) {
        const roundId = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).substring(2, 15);
        
        const checklist = {
            grammar: { completed: false, tasks: { read: false, examples: false, structure: false, rules: false, mistakes: false } },
            vocabulary: { completed: false },
            quizfreely: { completed: false, score: '', questions: '', tasks: { vocab: false, grammar: false, sentence: false, wrong: false } },
            reading: { completed: false, score: '', tasks: { first: false, grammar: false, vocab: false, comp: false, gram: false } },
            listening: { completed: false, score: '', tasks: { round1: false, round2: false, round3: false, round4: false, round5: false } },
            writing: { completed: false, scores: { grammar: '', vocab: '', clarity: '' }, tasks: { level1: false, level2: false, level3: false, checkGrammar: false, checkVerb: false, checkOrder: false, checkVocab: false, checkSpell: false, checkPunct: false } },
            speaking: { completed: false, scores: { grammar: '', vocab: '', fluency: '', pronunc: '' }, tasks: { level1: false, level2: false, level3: false, level4: false, checkGrammar: false, checkVocab: false, checkRead: false, checkListen: false } },
            massiveExercises: { completed: false, scoreInfo: { total: '', correct: '', wrong: '', percent: '' }, tasks: { cat1: false, cat2: false, cat3: false, cat4: false, cat5: false, cat6: false, cat7: false, cat8: false } },
            errorReview: { completed: false, errors: [] },
            checkpoint: { completed: false, passed: false, scores: { grammar: '', vocab: '', reading: '', listening: '', writing: '', speaking: '', mixed: '' }, overall: '' }
        };

        const newRound = {
            id: roundId,
            tenseId,
            name,
            description,
            vocabularyInfo,
            checklist,
            createdAt: Date.now()
        };

        // Update state
        roundsData[roundId] = newRound;

        if (!tensesData[tenseId]) {
            tensesData[tenseId] = { id: tenseId, name: tenseId, description: '', roundIds: [] };
        }
        tensesData[tenseId].roundIds.push(roundId);

        // Save to IndexedDB
        await db.waveRounds.put($state.snapshot(newRound));
        await db.waveTenses.put($state.snapshot(tensesData[tenseId]));
        
        // Push to Sync Queue
        await db.syncQueue.add({
            timestamp: Date.now(),
            action: 'CREATE_ROUND',
            payload: { roundId, tenseId }
        });

        return roundId;
    }

    async function updateRoundState(roundId, mutateFn) {
        if (roundsData[roundId]) {
            mutateFn(roundsData[roundId]);
            const snapshot = $state.snapshot(roundsData[roundId]);
            
            await db.waveRounds.put(snapshot);
            
            // Push to Sync Queue
            await db.syncQueue.add({
                timestamp: Date.now(),
                action: 'UPDATE_ROUND',
                payload: { roundId }
            });
        }
    }
    
    function getRoundProgress(roundId) {
        const round = roundsData[roundId];
        if (!round) return { completed: 0, total: 10, percent: 0, status: 'NOT STARTED' };
        
        let completed = 0;
        let core9Completed = 0;
        
        for (const step of CHECKLIST_STEPS) {
            if (round.checklist[step.id]?.completed) {
                completed++;
                if (step.id !== 'checkpoint') core9Completed++;
            }
        }
        
        const percent = Math.round((completed / 10) * 100);
        let status = 'IN PROGRESS';
        
        if (completed === 0) {
            status = 'NOT STARTED';
        } else if (core9Completed === 9 && !round.checklist.checkpoint.completed) {
            status = 'READY FOR CHECKPOINT';
        } else if (round.checklist.checkpoint.completed) {
            if (round.checklist.checkpoint.passed) {
                status = 'COMPLETED';
            } else {
                status = 'NEEDS REVIEW';
            }
        }
        
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
        updateRoundState,
        getRoundProgress,
        getTenseProgress
    };
}

export const trackerState = createTrackerState();
