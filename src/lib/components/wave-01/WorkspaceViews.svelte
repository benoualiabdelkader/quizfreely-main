<script>
    import { trackerState } from "$lib/trackerState.svelte.js";

    let { round, activeStage, onClose } = $props();

    function markComplete() {
        trackerState.updateRoundState(round.id, r => {
            r.checklist[activeStage].completed = true;
        });
        onClose();
    }
    
    function saveState() {
        trackerState.save();
    }
    
    function addError(e) {
        e.preventDefault();
        const form = e.target;
        const wrong = form.wrong.value;
        const correct = form.correct.value;
        const why = form.why.value;
        if (!wrong || !correct) return;
        
        trackerState.updateRoundState(round.id, r => {
            r.checklist.errorReview.errors.push({
                id: (typeof crypto !== 'undefined' && crypto.randomUUID) ? crypto.randomUUID() : Math.random().toString(),
                wrong,
                correct,
                why,
                status: { reviewed: false, understood: false, practiced: false, fixed: false }
            });
        });
        form.reset();
    }
    
    function toggleErrorStatus(errorId, field) {
        trackerState.updateRoundState(round.id, r => {
            const err = r.checklist.errorReview.errors.find(e => e.id === errorId);
            if (err) err.status[field] = !err.status[field];
        });
    }

    function evalCheckpoint() {
        trackerState.updateRoundState(round.id, r => {
            const s = r.checklist.checkpoint.scores;
            const sum = Number(s.grammar||0) + Number(s.vocab||0) + Number(s.reading||0) + Number(s.listening||0) + Number(s.writing||0) + Number(s.speaking||0) + Number(s.mixed||0);
            const avg = Math.round(sum / 7);
            r.checklist.checkpoint.overall = avg;
            r.checklist.checkpoint.passed = avg >= 80;
            r.checklist.checkpoint.completed = true;
        });
        onClose();
    }
</script>

<div class="workspace-header flex justify-between" style="margin-bottom: 1.5rem; align-items: center;">
    <button class="button alt" style="background: rgba(255,255,255,0.05);" onclick={onClose}>&larr; Back to Round Checklist</button>
</div>

<div class="glass-panel" style="padding: 2.5rem; border-radius: var(--radius-xl); margin-bottom: 3rem;">
    {#if activeStage === 'grammar'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">1. Grammar</h2>
        <p class="fg1">Understand the grammar before intensive practice.</p>
        
        <div style="margin: 2rem 0; padding: 1.5rem; background: rgba(0,0,0,0.2); border-radius: var(--radius-md);">
            <h3>A. Grammar Target</h3>
            <p style="text-transform: capitalize;">{round.tenseId.replace('-', ' ')}</p>
            
            <h3>B. When We Use It & Structure</h3>
            <p class="fg1">Refer to your primary learning material for specific usage, patterns, and structures of this tense.</p>
        </div>
        
        <h3 style="margin-bottom: 1rem;">Grammar Tasks</h3>
        <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.grammar.tasks.read} onchange={saveState} /> Read explanation</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.grammar.tasks.examples} onchange={saveState} /> Study examples</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.grammar.tasks.structure} onchange={saveState} /> Identify sentence structure</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.grammar.tasks.rules} onchange={saveState} /> Identify important rules</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.grammar.tasks.mistakes} onchange={saveState} /> Review common mistakes</label>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Grammar Complete</button>

    {:else if activeStage === 'vocabulary'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">2. Vocabulary</h2>
        <p class="fg1">Master the vocabulary belonging to this Round.</p>
        <p class="fg1" style="color: #03DAC6; font-weight: 500;">Target: {round.vocabularyInfo || 'No specific vocab defined'}</p>
        
        <div style="margin: 2rem 0; padding: 1.5rem; background: rgba(0,0,0,0.2); border-radius: var(--radius-md);">
            <h3>Vocabulary Practice Methods</h3>
            <ul class="fg1" style="line-height: 1.8;">
                <li>Word &rarr; Meaning / Meaning &rarr; Word</li>
                <li>Infinitive &rarr; Past Simple / Past Simple &rarr; Infinitive</li>
                <li>Fill in the blank & Matching</li>
                <li>Word grouping & Example sentence recognition</li>
            </ul>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Vocabulary Complete</button>

    {:else if activeStage === 'quizfreely'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">3. Quizfreely</h2>
        <p class="fg1">Use Quizfreely for active recall. This stage focuses on retrieval.</p>
        
        <div style="margin: 2rem 0; padding: 1.5rem; background: rgba(0,0,0,0.2); border-radius: var(--radius-md);">
            <h3 style="margin-top: 0;">Quizfreely Study Set</h3>
            <p class="fg1">"{round.name}"</p>
            <a href="/home" target="_blank" class="button alt" style="display: inline-flex; margin-top: 0.5rem;">Open Quizfreely in New Tab</a>
        </div>
        
        <h3 style="margin-bottom: 1rem;">Checklist</h3>
        <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.quizfreely.tasks.vocab} onchange={saveState} /> Completed vocabulary recall</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.quizfreely.tasks.grammar} onchange={saveState} /> Completed grammar recall</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.quizfreely.tasks.sentence} onchange={saveState} /> Completed sentence exercises</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.quizfreely.tasks.wrong} onchange={saveState} /> Reviewed wrong answers</label>
        </div>
        
        <div class="flex compact-gap" style="margin-bottom: 2rem; max-width: 400px;">
            <div style="flex: 1;">
                <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Score (%)</label>
                <input type="number" class="input w-full" bind:value={round.checklist.quizfreely.score} onchange={saveState} placeholder="e.g. 87" />
            </div>
            <div style="flex: 1;">
                <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Questions</label>
                <input type="text" class="input w-full" bind:value={round.checklist.quizfreely.questions} onchange={saveState} placeholder="e.g. 45/50" />
            </div>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Quizfreely Complete</button>

    {:else if activeStage === 'reading'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">4. Reading</h2>
        <p class="fg1">Use the target grammar and vocabulary in real context (150–250 words).</p>
        
        <h3 style="margin-top: 2rem; margin-bottom: 1rem;">Reading Process</h3>
        <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.reading.tasks.first} onchange={saveState} /> <strong>Step 1:</strong> First reading (general meaning)</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.reading.tasks.grammar} onchange={saveState} /> <strong>Step 2:</strong> Grammar identification</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.reading.tasks.vocab} onchange={saveState} /> <strong>Step 3:</strong> Vocabulary identification</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.reading.tasks.comp} onchange={saveState} /> <strong>Step 4:</strong> Answer comprehension questions</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.reading.tasks.gram} onchange={saveState} /> <strong>Step 5:</strong> Answer grammar questions</label>
        </div>
        
        <div style="margin-bottom: 2rem; max-width: 200px;">
            <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Comprehension Score (%)</label>
            <input type="number" class="input w-full" bind:value={round.checklist.reading.score} onchange={saveState} placeholder="e.g. 90" />
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Reading Complete</button>

    {:else if activeStage === 'listening'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">5. Listening</h2>
        <p class="fg1">Understand the target grammar and vocabulary when spoken.</p>
        
        <h3 style="margin-top: 2rem; margin-bottom: 1rem;">Listening Workflow</h3>
        <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.listening.tasks.round1} onchange={saveState} /> <strong>Round 1 (Listen Only):</strong> Do not read the text.</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.listening.tasks.round2} onchange={saveState} /> <strong>Round 2 (Listen + Read):</strong> Listen while reading.</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.listening.tasks.round3} onchange={saveState} /> <strong>Round 3 (Repeat):</strong> Listen and repeat each sentence.</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.listening.tasks.round4} onchange={saveState} /> <strong>Round 4 (Shadowing):</strong> Speak immediately with the audio.</label>
            <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.listening.tasks.round5} onchange={saveState} /> <strong>Round 5 (Understanding):</strong> Answer questions blindly.</label>
        </div>
        
        <div style="margin-bottom: 2rem; max-width: 200px;">
            <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Listening Score (%)</label>
            <input type="number" class="input w-full" bind:value={round.checklist.listening.score} onchange={saveState} placeholder="e.g. 85" />
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Listening Complete</button>

    {:else if activeStage === 'writing'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">6. Writing</h2>
        <p class="fg1">Produce the grammar independently.</p>
        
        <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2rem;">
            <div>
                <h3 style="margin-top: 1rem; margin-bottom: 1rem;">Writing Levels</h3>
                <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.level1} onchange={saveState} /> <strong>Level 1 (Controlled):</strong> Write 5 target sentences.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.level2} onchange={saveState} /> <strong>Level 2 (Guided):</strong> Use this Round's vocabulary.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.level3} onchange={saveState} /> <strong>Level 3 (Free):</strong> Write a short paragraph (80-120 words).</label>
                </div>
                
                <h3 style="margin-top: 1rem; margin-bottom: 1rem;">Writing Review</h3>
                <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.checkGrammar} onchange={saveState} /> Grammar</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.checkVerb} onchange={saveState} /> Verb forms</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.checkOrder} onchange={saveState} /> Word order</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.checkVocab} onchange={saveState} /> Vocabulary</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.checkSpell} onchange={saveState} /> Spelling</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.writing.tasks.checkPunct} onchange={saveState} /> Punctuation</label>
                </div>
            </div>
            
            <div style="background: rgba(0,0,0,0.2); padding: 1.5rem; border-radius: var(--radius-md);">
                <h3 style="margin-top: 0; margin-bottom: 1rem;">Optional Self-Score (/10)</h3>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Grammar</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.writing.scores.grammar} onchange={saveState} />
                </div>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Vocabulary</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.writing.scores.vocab} onchange={saveState} />
                </div>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Clarity</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.writing.scores.clarity} onchange={saveState} />
                </div>
            </div>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Writing Complete</button>

    {:else if activeStage === 'speaking'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">7. Speaking</h2>
        <p class="fg1">Produce the grammar naturally through speech.</p>
        
        <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2rem;">
            <div>
                <h3 style="margin-top: 1rem; margin-bottom: 1rem;">Speaking Levels</h3>
                <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.level1} onchange={saveState} /> <strong>Level 1:</strong> Read target sentences aloud.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.level2} onchange={saveState} /> <strong>Level 2:</strong> Answer 5 questions aloud.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.level3} onchange={saveState} /> <strong>Level 3:</strong> Speak for 30–60 seconds (guided).</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.level4} onchange={saveState} /> <strong>Level 4:</strong> Speak for 1-2 minutes without reading.</label>
                </div>
                
                <h3 style="margin-top: 1rem; margin-bottom: 1rem;">After Recording</h3>
                <div class="flex col" style="gap: 0.5rem; margin-bottom: 2rem;">
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.checkGrammar} onchange={saveState} /> I used the target grammar.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.checkVocab} onchange={saveState} /> I used Round vocabulary.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.checkRead} onchange={saveState} /> I spoke without reading.</label>
                    <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.speaking.tasks.checkListen} onchange={saveState} /> I listened to my recording.</label>
                </div>
            </div>
            
            <div style="background: rgba(0,0,0,0.2); padding: 1.5rem; border-radius: var(--radius-md);">
                <h3 style="margin-top: 0; margin-bottom: 1rem;">Optional Self-Score (/10)</h3>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Grammar</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.speaking.scores.grammar} onchange={saveState} />
                </div>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Vocabulary</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.speaking.scores.vocab} onchange={saveState} />
                </div>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Fluency</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.speaking.scores.fluency} onchange={saveState} />
                </div>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Pronunciation</label>
                    <input type="number" max="10" class="input w-full" bind:value={round.checklist.speaking.scores.pronunc} onchange={saveState} />
                </div>
            </div>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Speaking Complete</button>

    {:else if activeStage === 'massiveExercises'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">8. Massive Exercises</h2>
        <p class="fg1">Build automaticity through many different exercise types.</p>
        
        <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2rem; margin-top: 2rem;">
            <div class="flex col" style="gap: 0.5rem;">
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat1} onchange={saveState} /> Multiple Choice (20q)</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat2} onchange={saveState} /> Fill in the blank (20q)</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat3} onchange={saveState} /> Matching (20q)</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat4} onchange={saveState} /> Unscramble (20q)</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat5} onchange={saveState} /> Regroup / Classify</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat6} onchange={saveState} /> Error Correction (20q)</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat7} onchange={saveState} /> Translation / Meaning</label>
                <label class="flex center compact-gap checkbox-label"><input type="checkbox" bind:checked={round.checklist.massiveExercises.tasks.cat8} onchange={saveState} /> Mixed Challenge (30-50q)</label>
            </div>
            
            <div style="background: rgba(0,0,0,0.2); padding: 1.5rem; border-radius: var(--radius-md);">
                <h3 style="margin-top: 0; margin-bottom: 1rem;">Summary</h3>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Total exercises</label>
                    <input type="number" class="input w-full" bind:value={round.checklist.massiveExercises.scoreInfo.total} onchange={saveState} />
                </div>
                <div class="flex gap-4" style="margin-bottom: 1rem; gap: 1rem;">
                    <div style="flex: 1;">
                        <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block; color: #03DAC6;">Correct</label>
                        <input type="number" class="input w-full" bind:value={round.checklist.massiveExercises.scoreInfo.correct} onchange={saveState} />
                    </div>
                    <div style="flex: 1;">
                        <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block; color: #FF6B6B;">Wrong</label>
                        <input type="number" class="input w-full" bind:value={round.checklist.massiveExercises.scoreInfo.wrong} onchange={saveState} />
                    </div>
                </div>
                <div style="margin-bottom: 1rem;">
                    <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Score (%)</label>
                    <input type="number" class="input w-full" bind:value={round.checklist.massiveExercises.scoreInfo.percent} onchange={saveState} />
                </div>
            </div>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Massive Exercises Complete</button>

    {:else if activeStage === 'errorReview'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">9. Error Review</h2>
        <p class="fg1" style="margin-bottom: 2rem;">Turn mistakes into learning. Create and review your Error Log.</p>
        
        <div class="grid" style="grid-template-columns: 1fr 2fr; gap: 2rem; margin-bottom: 2rem;">
            <div style="background: rgba(0,0,0,0.2); padding: 1.5rem; border-radius: var(--radius-md); height: fit-content;">
                <h3 style="margin-top: 0; margin-bottom: 1rem;">Log New Error</h3>
                <form onsubmit={addError}>
                    <div style="margin-bottom: 1rem;">
                        <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block; color: #FF6B6B;">Wrong Sentence</label>
                        <input name="wrong" required type="text" class="input w-full" placeholder="e.g. He go to school yesterday." />
                    </div>
                    <div style="margin-bottom: 1rem;">
                        <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block; color: #03DAC6;">Correct Sentence</label>
                        <input name="correct" required type="text" class="input w-full" placeholder="e.g. He went to school yesterday." />
                    </div>
                    <div style="margin-bottom: 1.5rem;">
                        <label class="fg1" style="font-size: 0.9rem; margin-bottom: 0.25rem; display: block;">Why?</label>
                        <input name="why" type="text" class="input w-full" placeholder="e.g. Past Simple uses 'went'" />
                    </div>
                    <button type="submit" class="button alt w-full" style="justify-content: center;">+ Add to Error Log</button>
                </form>
            </div>
            
            <div>
                <h3 style="margin-top: 0; margin-bottom: 1rem;">Error Log ({round.checklist.errorReview.errors.length})</h3>
                {#if round.checklist.errorReview.errors.length === 0}
                    <p class="fg1">No errors logged yet.</p>
                {:else}
                    <div class="flex col" style="gap: 1rem;">
                        {#each round.checklist.errorReview.errors as err, idx}
                            <div style="border: 1px solid rgba(255,255,255,0.1); border-radius: var(--radius-md); padding: 1rem;">
                                <div style="margin-bottom: 0.5rem;"><strong style="color: #FF6B6B;">Wrong:</strong> {err.wrong}</div>
                                <div style="margin-bottom: 0.5rem;"><strong style="color: #03DAC6;">Correct:</strong> {err.correct}</div>
                                <div style="margin-bottom: 1rem; font-size: 0.9rem; color: var(--fg-1);"><strong>Why:</strong> {err.why}</div>
                                
                                <div class="flex compact-gap" style="font-size: 0.85rem; flex-wrap: wrap;">
                                    <label class="flex center compact-gap" style="margin-right: 1rem;"><input type="checkbox" checked={err.status.reviewed} onchange={() => toggleErrorStatus(err.id, 'reviewed')} /> Reviewed</label>
                                    <label class="flex center compact-gap" style="margin-right: 1rem;"><input type="checkbox" checked={err.status.understood} onchange={() => toggleErrorStatus(err.id, 'understood')} /> Understood</label>
                                    <label class="flex center compact-gap" style="margin-right: 1rem;"><input type="checkbox" checked={err.status.practiced} onchange={() => toggleErrorStatus(err.id, 'practiced')} /> Practiced again</label>
                                    <label class="flex center compact-gap"><input type="checkbox" checked={err.status.fixed} onchange={() => toggleErrorStatus(err.id, 'fixed')} /> Fixed</label>
                                </div>
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>
        </div>
        
        <button class="button main" onclick={markComplete}>Mark Error Review Complete</button>

    {:else if activeStage === 'checkpoint'}
        <h2 style="margin-top: 0; font-size: 2rem;" class="text-gradient">10. Checkpoint</h2>
        <p class="fg1" style="margin-bottom: 2rem;">Final test before declaring the Round complete. Test EVERYTHING from the Round.</p>
        
        <div class="grid" style="grid-template-columns: 1fr 1fr; gap: 2rem; margin-bottom: 2.5rem;">
            <div>
                <h3 style="margin-top: 0; margin-bottom: 1.5rem;">Enter Scores (%)</h3>
                
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 1 - Grammar (10q)</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.grammar} />
                </div>
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 2 - Vocabulary (10q)</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.vocab} />
                </div>
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 3 - Reading</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.reading} />
                </div>
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 4 - Listening</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.listening} />
                </div>
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 5 - Writing</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.writing} />
                </div>
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 6 - Speaking</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.speaking} />
                </div>
                <div class="flex justify-between" style="margin-bottom: 1rem; align-items: center;">
                    <label class="fg1">Part 7 - Mixed Grammar</label>
                    <input type="number" class="input" style="width: 80px;" bind:value={round.checklist.checkpoint.scores.mixed} />
                </div>
            </div>
            
            <div style="background: rgba(0,0,0,0.2); padding: 2rem; border-radius: var(--radius-md); display: flex; flex-direction: column; justify-content: center; align-items: center;">
                {#if round.checklist.checkpoint.completed}
                    <h3 style="margin-top: 0; color: var(--fg-1);">Overall Score</h3>
                    <div style="font-size: 4rem; font-weight: 800; color: {round.checklist.checkpoint.passed ? '#03DAC6' : '#FF6B6B'}; margin: 1rem 0;">
                        {round.checklist.checkpoint.overall}%
                    </div>
                    
                    {#if round.checklist.checkpoint.passed}
                        <div style="background: rgba(3, 218, 198, 0.15); color: #03DAC6; padding: 10px 20px; border-radius: 8px; font-weight: 700; font-size: 1.1rem; text-align: center;">
                            ✓ ROUND MASTERED
                        </div>
                        <p class="fg1" style="text-align: center; margin-top: 1rem;">Round completed successfully. You can now create another Round.</p>
                    {:else}
                        <div style="background: rgba(255, 107, 107, 0.15); color: #FF6B6B; padding: 10px 20px; border-radius: 8px; font-weight: 700; font-size: 1.1rem; text-align: center;">
                            ⚠ NEEDS REVIEW
                        </div>
                        <p class="fg1" style="text-align: center; margin-top: 1rem;">Score is below the 80% passing threshold. Please review your weak areas and try again.</p>
                    {/if}
                {:else}
                    <p class="fg1" style="text-align: center; font-size: 1.1rem;">Enter your scores on the left and click Evaluate to calculate your final result.</p>
                {/if}
            </div>
        </div>
        
        <button class="button main w-full" style="justify-content: center; height: 3.5rem; font-size: 1.1rem;" onclick={evalCheckpoint}>
            Evaluate Checkpoint & Finish Round
        </button>
    {/if}
</div>

<style>
    .checkbox-label {
        padding: 0.5rem;
        border-radius: var(--radius-md);
        transition: background 0.2s;
        cursor: pointer;
    }
    .checkbox-label:hover {
        background: rgba(255,255,255,0.05);
    }
    input[type="checkbox"] {
        transform: scale(1.2);
        margin-right: 0.5rem;
    }
    .w-full {
        width: 100%;
        box-sizing: border-box;
    }
</style>
