<script>
    import { page } from "$app/state";
    import { onMount } from "svelte";
    import { trackerState } from "$lib/trackerState.svelte.js";
    import IconPlus from "$lib/icons/Plus.svelte";

    let tenseId = $derived(page.params.tenseId);
    let tense = $derived(trackerState.tenses[tenseId]);
    let progress = $derived(trackerState.getTenseProgress(tenseId));

    let showModal = $state(false);
    let newRoundName = $state("");
    let newRoundDesc = $state("");
    let newRoundVocab = $state("");

    onMount(() => {
        trackerState.init();
    });

    function handleCreateRound() {
        if (!newRoundName.trim()) return;
        trackerState.createRound(tenseId, newRoundName, newRoundDesc, newRoundVocab);
        showModal = false;
        newRoundName = "";
        newRoundDesc = "";
        newRoundVocab = "";
    }
</script>

<svelte:head>
    <title>{tense ? tense.name : 'Tense'} | Wave 01 Tracker</title>
</svelte:head>

<div class="content" style="padding-top: 2rem;">
    {#if !trackerState.loaded || !tense}
        <div class="flex center" style="height: 200px;">
            <p class="fg1">Loading tense...</p>
        </div>
    {:else}
        <a href="/wave-01" class="fg1" style="display: inline-block; margin-bottom: 1rem; text-decoration: none; font-weight: 500;">&larr; Back to Tracker</a>
        
        <div class="glass-panel" style="padding: 2.5rem; border-radius: var(--radius-xl); margin-bottom: 2.5rem;">
            <h1 class="text-gradient" style="margin-top: 0; margin-bottom: 0.5rem; font-size: 2.5rem;">{tense.name}</h1>
            <p class="fg1" style="font-size: 1.1rem; margin-bottom: 2rem; max-width: 600px;">{tense.description}</p>
            
            <div class="flex" style="gap: 3rem; margin-bottom: 2.5rem; flex-wrap: wrap;">
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Overall Progress</p>
                    <div class="flex center" style="gap: 1rem; min-width: 200px;">
                        <div style="flex-grow: 1; height: 12px; background: rgba(255,255,255,0.1); border-radius: 6px; overflow: hidden;">
                            <div style="height: 100%; width: {progress.percent}%; background: linear-gradient(90deg, var(--main), #03DAC6); transition: width 0.4s ease;"></div>
                        </div>
                        <span style="font-weight: 700; font-size: 1.2rem;">{progress.percent}%</span>
                    </div>
                </div>
                
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Total Rounds</p>
                    <p style="margin: 0; font-size: 1.2rem; font-weight: 600;">{progress.totalRounds}</p>
                </div>
                
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Completed</p>
                    <p style="margin: 0; font-size: 1.2rem; font-weight: 600; color: #03DAC6;">{progress.completedRounds}</p>
                </div>
                
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Active</p>
                    <p style="margin: 0; font-size: 1.2rem; font-weight: 600; color: var(--main);">{progress.totalRounds - progress.completedRounds}</p>
                </div>
            </div>
            
            <button class="button main" style="height: 3rem; padding: 0 2rem; font-size: 1.05rem;" onclick={() => showModal = true}>
                <IconPlus /> Create New Round
            </button>
        </div>

        <h2 style="margin-bottom: 1.5rem; font-size: 1.75rem;">Rounds</h2>
        
        {#if tense.roundIds.length === 0}
            <div class="glass-panel" style="padding: 3rem; text-align: center; border-radius: var(--radius-xl);">
                <p class="fg1" style="font-size: 1.1rem; margin-bottom: 1.5rem;">You haven't created any rounds for this tense yet.</p>
                <button class="button main" onclick={() => showModal = true}><IconPlus /> Create Your First Round</button>
            </div>
        {:else}
            <div class="grid" style="grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1.5rem;">
                {#each tense.roundIds as roundId, i}
                    {@const round = trackerState.rounds[roundId]}
                    {@const rProgress = trackerState.getRoundProgress(roundId)}
                    
                    <a href="/wave-01/round/{roundId}" class="glass-panel" style="display: flex; flex-direction: column; padding: 1.5rem; border-radius: var(--radius-xl); text-decoration: none; color: inherit; transition: transform 0.2s, box-shadow 0.2s;">
                        <div class="flex justify-between" style="margin-bottom: 0.5rem; align-items: flex-start;">
                            <h3 style="margin: 0; font-size: 1.25rem;">{round.name || `Round ${i + 1}`}</h3>
                            {#if rProgress.status === 'COMPLETED'}
                                <span style="background: rgba(3, 218, 198, 0.15); color: #03DAC6; padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">COMPLETED</span>
                            {:else if rProgress.status === 'IN PROGRESS'}
                                <span style="background: rgba(108, 99, 255, 0.15); color: var(--main); padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">IN PROGRESS</span>
                            {:else}
                                <span style="background: rgba(255, 255, 255, 0.1); color: var(--fg-1); padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">NOT STARTED</span>
                            {/if}
                        </div>
                        
                        {#if round.vocabularyInfo}
                            <p class="fg1" style="font-size: 0.9rem; margin-top: 0; margin-bottom: 1rem;"><strong>Vocab:</strong> {round.vocabularyInfo}</p>
                        {/if}
                        
                        {#if round.description}
                            <p class="fg1" style="font-size: 0.95rem; margin-bottom: 1.5rem; flex-grow: 1;">{round.description}</p>
                        {:else}
                            <div style="flex-grow: 1;"></div>
                        {/if}
                        
                        <div class="flex center" style="gap: 0.75rem; margin-top: 1.5rem;">
                            <div style="flex-grow: 1; height: 8px; background: rgba(255,255,255,0.1); border-radius: 4px; overflow: hidden;">
                                <div style="height: 100%; width: {rProgress.percent}%; background: {rProgress.percent === 100 ? '#03DAC6' : 'var(--main)'}; transition: width 0.3s ease;"></div>
                            </div>
                            <span style="font-weight: 600; font-size: 0.95rem;">{rProgress.percent}%</span>
                        </div>
                    </a>
                {/each}
            </div>
        {/if}
    {/if}
</div>

{#if showModal}
    <div class="modal-backdrop flex center" style="position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.6); backdrop-filter: blur(8px); z-index: 1000; padding: 1rem;">
        <div class="glass-panel" style="width: 100%; max-width: 500px; padding: 2.5rem; border-radius: var(--radius-xl);">
            <h2 style="margin-top: 0; margin-bottom: 1.5rem;">Create Round</h2>
            
            <p class="fg1" style="margin-bottom: 1.5rem; font-size: 0.95rem; line-height: 1.5;">
                Tense: <strong class="fg0">{tense?.name}</strong><br>
                <span style="font-size: 0.85rem; opacity: 0.8;">You can create unlimited rounds inside the same tense. Every round has its own independent 10-step checklist.</span>
            </p>
            
            <div style="margin-bottom: 1.25rem;">
                <label for="roundName" class="fg1" style="display: block; margin-bottom: 0.5rem; font-size: 0.9rem; font-weight: 500;">Round name</label>
                <input id="roundName" type="text" bind:value={newRoundName} placeholder="e.g. Past Simple — Verbs 1–10" class="input" style="width: 100%; padding: 0.85rem; background: rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.1); border-radius: var(--radius-md); color: var(--fg-0);" />
            </div>
            
            <div style="margin-bottom: 1.25rem;">
                <label for="roundDesc" class="fg1" style="display: block; margin-bottom: 0.5rem; font-size: 0.9rem; font-weight: 500;">Description (Optional)</label>
                <input id="roundDesc" type="text" bind:value={newRoundDesc} placeholder="e.g. First 10 irregular verbs." class="input" style="width: 100%; padding: 0.85rem; background: rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.1); border-radius: var(--radius-md); color: var(--fg-0);" />
            </div>
            
            <div style="margin-bottom: 2.5rem;">
                <label for="roundVocab" class="fg1" style="display: block; margin-bottom: 0.5rem; font-size: 0.9rem; font-weight: 500;">Vocabulary / number of verbs (Optional)</label>
                <input id="roundVocab" type="text" bind:value={newRoundVocab} placeholder="e.g. 10 verbs" class="input" style="width: 100%; padding: 0.85rem; background: rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.1); border-radius: var(--radius-md); color: var(--fg-0);" />
            </div>
            
            <div class="flex justify-between compact-gap">
                <button class="button alt" style="flex: 1; justify-content: center; height: 3rem; background: rgba(255,255,255,0.05);" onclick={() => showModal = false}>Cancel</button>
                <button class="button main" style="flex: 1; justify-content: center; height: 3rem;" onclick={handleCreateRound} disabled={!newRoundName.trim()}>Create Round</button>
            </div>
        </div>
    </div>
{/if}
