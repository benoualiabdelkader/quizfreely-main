<script>
    import { onMount } from "svelte";
    import Card from "$lib/components/ui/Card.svelte";
    import Input from "$lib/components/ui/Input.svelte";
    let { data } = $props();
    
    let searchQuery = $state("");
    
    let filteredSubjects = $derived(
        data?.allSubjects?.filter(s => s.name.toLowerCase().includes(searchQuery.toLowerCase())) || []
    );
    
    let groupedSubjects = $derived(() => {
        const groups = {};
        for (const s of filteredSubjects) {
            const cat = s.category || "Other";
            if (!groups[cat]) groups[cat] = [];
            groups[cat].push(s);
        }
        return groups;
    });
</script>

<svelte:head>
    <title>Explore & Search - Quizfreely</title>
</svelte:head>

<div style="margin-bottom: 2.5rem; display: flex; flex-direction: column; gap: 1rem;">
    <h2 style="margin: 0;">Explore Subjects</h2>
    <div style="max-width: 400px;">
        <Input type="text" placeholder="Search subjects..." bind:value={searchQuery} />
    </div>
</div>

<div class="flex col" style="gap: 3rem;">
    {#each Object.entries(groupedSubjects()) as [category, subjects]}
        <details class="subject-category" open>
            <summary style="cursor: pointer; margin-bottom: 1rem; list-style-type: none; display: flex; align-items: center; gap: 0.5rem;">
                <h3 style="margin: 0; color: var(--fg-0); font-size: 1.25rem;">{category}</h3>
                <span style="background: var(--bg-2); padding: 2px 8px; border-radius: 12px; font-size: 0.85rem; color: var(--fg-1);">{subjects.length}</span>
            </summary>
            <div class="grid list" style="grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1.5rem; margin-top: 1rem;">
                {#each subjects as subject}
                    <a href="/subjects/{subject.id}" style="text-decoration: none;">
                        <Card interactive={true} style="padding: 1.25rem; height: 100%; display: flex; align-items: center;">
                            <span style="color: var(--fg-0); font-weight: 500;">{subject.name}</span>
                        </Card>
                    </a>
                {/each}
            </div>
        </details>
    {/each}
</div>

<style>
    .subject-category summary::-webkit-details-marker {
        display: none;
    }
</style>
