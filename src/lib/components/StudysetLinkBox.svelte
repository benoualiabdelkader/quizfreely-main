<script>
    let {
        studyset,
        linkTemplateFunc,
        showDropdown = false,
        dropdownContent
    } = $props();
    import Dropdown from "$lib/components/Dropdown.svelte";
    import MoreIcon from "$lib/icons/MoreDotsVertical.svelte";
</script>
<div>
    <a href={linkTemplateFunc(studyset.id)} class="glass-panel" style="display: flex; flex-direction: column; text-align: start; justify-content: space-between; height: 100%; padding: 1.5rem; border-radius: var(--radius-lg); text-decoration: none; transition: transform var(--transition-bounce), box-shadow var(--transition-fast);">
        <p class="h3" style="margin: 0 0 0.5rem 0; font-family: 'Outfit', sans-serif; font-weight: 700; color: var(--fg-0); line-height: 1.2;">{ studyset.title }</p>
        <div style="display: inline-flex; align-items: center; background: rgba(255,255,255,0.05); padding: 0.2rem 0.6rem; border-radius: 1rem; width: fit-content;">
            <p class="h6" style="margin: 0; color: var(--fg-1); font-weight: 500;">{studyset.termsCount ?? 0} {studyset.termsCount == 1 ? "Term" : "Terms"}</p>
        </div>
    </a>
    {#if showDropdown}
    <div class="flex" style="justify-content: end; position: relative; margin-top: 0px; margin-bottom: 0px;">
        <Dropdown button={{class:"dropdown-toggle"}} container={{style:"position: absolute; bottom: 0.2rem;"}}>
            {#snippet buttonContent()}
                <MoreIcon class="text fg0"></MoreIcon>
            {/snippet}
            {#snippet divContent(hideFunc)}
                {@render dropdownContent?.(studyset, hideFunc)}
            {/snippet}
        </Dropdown>
    </div>
    {/if}
</div>
