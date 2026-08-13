<script>
    import { page } from "$app/state";
    import { onMount } from "svelte";
    import { trackerState, CHECKLIST_STEPS } from "$lib/trackerState.svelte.js";
    import CheckmarkIcon from "$lib/icons/Checkmark.svelte";

    let roundId = $derived(page.params.roundId);
    let round = $derived(trackerState.rounds[roundId]);
    let tense = $derived(round ? trackerState.tenses[round.tenseId] : null);
    let rProgress = $derived(trackerState.getRoundProgress(roundId));

    onMount(() => {
        trackerState.init();
    });

    function toggleStep(stepId) {
        trackerState.toggleChecklistStep(roundId, stepId);
    }
</script>

<svelte:head>
    <title>{round ? round.name : 'Round'} | Wave 01 Tracker</title>
</svelte:head>

<div class="content" style="padding-top: 2rem;">
    {#if !trackerState.loaded || !round || !tense}
        <div class="flex center" style="height: 200px;">
            <p class="fg1">Loading round...</p>
        </div>
    {:else}
        <div style="margin-bottom: 2rem;">
            <a href="/wave-01/tense/{tense.id}" class="fg1" style="display: inline-block; margin-bottom: 1rem; text-decoration: none; font-weight: 500;">
                &larr; Back to {tense.name}
            </a>
            <p class="fg1" style="margin: 0; font-size: 1rem; text-transform: uppercase; letter-spacing: 2px;">{tense.name}</p>
            <h1 class="text-gradient" style="margin-top: 0.25rem; margin-bottom: 0.5rem; font-size: 2.5rem;">{round.name || 'Untitled Round'}</h1>
            
            {#if round.description}
                <p class="fg1" style="margin-bottom: 0.5rem; font-size: 1.1rem;">{round.description}</p>
            {/if}
            {#if round.vocabularyInfo}
                <p class="fg1" style="margin-top: 0; font-size: 1rem; font-weight: 500; color: #03DAC6;">Vocab: {round.vocabularyInfo}</p>
            {/if}
        </div>
        
        <div class="glass-panel" style="padding: 2.5rem; border-radius: var(--radius-xl); margin-bottom: 2rem;">
            <div class="flex justify-between" style="align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
                <h2 style="margin: 0;">Round Progress</h2>
                {#if rProgress.status === 'COMPLETED'}
                    <span style="background: rgba(3, 218, 198, 0.15); color: #03DAC6; padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">COMPLETED</span>
                {:else if rProgress.status === 'IN PROGRESS'}
                    <span style="background: rgba(108, 99, 255, 0.15); color: var(--main); padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">IN PROGRESS</span>
                {:else}
                    <span style="background: rgba(255, 255, 255, 0.1); color: var(--fg-1); padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">NOT STARTED</span>
                {/if}
            </div>
            
            <div class="flex center" style="gap: 1rem; margin-bottom: 3rem;">
                <div style="flex-grow: 1; height: 16px; background: rgba(255,255,255,0.1); border-radius: 8px; overflow: hidden; box-shadow: inset 0 2px 4px rgba(0,0,0,0.2);">
                    <div style="height: 100%; width: {rProgress.percent}%; background: linear-gradient(90deg, var(--main), #03DAC6); transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);"></div>
                </div>
                <span style="font-weight: 700; font-size: 1.5rem; width: 60px; text-align: right;">{rProgress.percent}%</span>
            </div>
            
            <h3 style="margin-bottom: 1.5rem; font-size: 1.25rem;">Mission Objectives (10-Step Checklist)</h3>
            
            <div class="flex col" style="gap: 0.75rem;">
                {#each CHECKLIST_STEPS as step, i}
                    {@const isCompleted = round.checklist[step.id]}
                    <button 
                        class="glass-panel" 
                        style="display: flex; align-items: center; padding: 1.25rem; border-radius: var(--radius-md); background: {isCompleted ? 'rgba(3, 218, 198, 0.05)' : 'rgba(255,255,255,0.02)'}; border: 1px solid {isCompleted ? 'rgba(3, 218, 198, 0.3)' : 'rgba(255,255,255,0.05)'}; cursor: pointer; text-align: left; transition: all 0.2s;"
                        onclick={() => toggleStep(step.id)}
                    >
                        <div class="flex center" style="justify-content: center; width: 32px; height: 32px; border-radius: 8px; margin-right: 1.5rem; background: {isCompleted ? '#03DAC6' : 'rgba(255,255,255,0.1)'}; border: 2px solid {isCompleted ? '#03DAC6' : 'rgba(255,255,255,0.3)'}; transition: all 0.2s;">
                            {#if isCompleted}
                                <CheckmarkIcon style="color: #000; width: 18px; height: 18px;" />
                            {/if}
                        </div>
                        <div style="flex-grow: 1;">
                            <span style="display: block; font-size: 0.85rem; color: var(--fg-1); margin-bottom: 0.2rem;">Step {i + 1}</span>
                            <span style="font-size: 1.15rem; font-weight: {isCompleted ? '600' : '400'}; color: {isCompleted ? 'var(--fg-0)' : 'var(--fg-1)'}; text-decoration: {isCompleted ? 'line-through' : 'none'}; opacity: {isCompleted ? '0.8' : '1'}; transition: all 0.2s;">{step.label}</span>
                        </div>
                    </button>
                {/each}
            </div>
        </div>
    {/if}
</div>

<style>
    button:hover {
        background: rgba(255,255,255,0.08) !important;
        transform: translateY(-2px);
    }
    button:active {
        transform: translateY(0);
    }
</style>
