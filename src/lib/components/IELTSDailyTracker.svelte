<script>
    import { onMount } from "svelte";
    import CheckmarkIcon from "$lib/icons/Checkmark.svelte";

    let trackerData = $state({});
    let loaded = $state(false);

    const skills = [
        { id: "listening", label: "Listening" },
        { id: "reading", label: "Reading" },
        { id: "writing", label: "Writing" },
        { id: "speaking", label: "Speaking" },
        { id: "vocabulary", label: "Vocabulary" },
        { id: "grammar", label: "Grammar" }
    ];

    let dates = $state([]);

    onMount(() => {
        // Generate last 14 days
        const generatedDates = [];
        const today = new Date();
        for (let i = 0; i < 14; i++) {
            const d = new Date(today);
            d.setDate(d.getDate() - i);
            const dateString = d.toISOString().split('T')[0];
            const formatted = d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
            generatedDates.push({ dateString, formatted, isToday: i === 0 });
        }
        dates = generatedDates;

        const stored = localStorage.getItem("ielts_tracker");
        if (stored) {
            try {
                trackerData = JSON.parse(stored);
            } catch (e) {
                trackerData = {};
            }
        }
        loaded = true;
    });

    $effect(() => {
        if (loaded) {
            localStorage.setItem("ielts_tracker", JSON.stringify(trackerData));
        }
    });

    function toggleSkill(dateString, skillId) {
        if (!trackerData[dateString]) trackerData[dateString] = {};
        trackerData[dateString][skillId] = !trackerData[dateString][skillId];
    }
</script>

<div class="glass-panel" style="margin-bottom: 2rem; padding: 1.5rem; overflow-x: auto; border-radius: var(--radius-xl);">
    <h2 class="text-gradient" style="margin-top: 0; margin-bottom: 1.5rem;">IELTS Daily Tracker</h2>
    <table style="width: 100%; border-collapse: collapse; text-align: center; min-width: 600px;">
        <thead>
            <tr>
                <th style="padding: 1rem; text-align: left; border-bottom: 2px solid rgba(255, 255, 255, 0.1);">Date</th>
                {#each skills as skill}
                    <th style="padding: 1rem; border-bottom: 2px solid rgba(255, 255, 255, 0.1);">{skill.label}</th>
                {/each}
            </tr>
        </thead>
        <tbody>
            {#each dates as { dateString, formatted, isToday }}
                <tr style="border-bottom: 1px solid rgba(255, 255, 255, 0.05);">
                    <td style="padding: 1rem; text-align: left; font-weight: 500;">
                        {formatted}
                        {#if isToday}
                            <span style="font-size: 0.8rem; color: var(--main); margin-left: 0.5rem; background: rgba(108, 99, 255, 0.15); padding: 2px 6px; border-radius: 4px;">Today</span>
                        {/if}
                    </td>
                    {#each skills as skill}
                        <td style="padding: 0.5rem;">
                            <button
                                class="button-box {trackerData[dateString]?.[skill.id] ? 'selected' : ''}"
                                style="width: 100%; height: 3rem; justify-content: center; padding: 0;"
                                onclick={() => toggleSkill(dateString, skill.id)}
                            >
                                {#if trackerData[dateString]?.[skill.id]}
                                    <CheckmarkIcon class="button-box-selected-icon" />
                                {/if}
                            </button>
                        </td>
                    {/each}
                </tr>
            {/each}
        </tbody>
    </table>
</div>

<style>
    th {
        color: var(--fg-1);
        font-weight: 600;
    }
    td {
        vertical-align: middle;
    }
</style>
