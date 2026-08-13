<script>
    let { data } = $props();
    import Card from "$lib/components/ui/Card.svelte";
    import Button from "$lib/components/ui/Button.svelte";
    import IconCheckmark from "$lib/icons/Checkmark.svelte";
</script>

<style>
  .theme-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 1.5rem;
    margin-bottom: 3rem;
  }
</style>

<h3 style="margin-top: 0; margin-bottom: 1rem;">Theme</h3>
<div class="theme-grid">
  <a href="/settings/themes/auto" style="text-decoration: none;">
    <Card interactive={true} style="text-align: center; border: {data.theme == 'auto' ? '2px solid var(--main)' : '2px solid transparent'}; padding: 1rem;">
      <img src="/immutable/img/theme-preview-auto.png" style="width:100%; border-radius: var(--radius-md);" alt="Auto Theme Preview">
      <p style="margin-bottom: 0; margin-top: 1rem; font-weight: 600; color: var(--fg-0);">Auto</p>
    </Card>
  </a>
  <a href="/settings/themes/dark" style="text-decoration: none;">
    <Card interactive={true} style="text-align: center; border: {data.theme == 'dark' ? '2px solid var(--main)' : '2px solid transparent'}; padding: 1rem;">
      <img src="/immutable/img/theme-preview-dark.png" style="width:100%; border-radius: var(--radius-md);" alt="Dark Theme Preview">
      <p style="margin-bottom: 0; margin-top: 1rem; font-weight: 600; color: var(--fg-0);">Dark</p>
    </Card>
  </a>
  <a href="/settings/themes/light" style="text-decoration: none;">
    <Card interactive={true} style="text-align: center; border: {data.theme == 'light' ? '2px solid var(--main)' : '2px solid transparent'}; padding: 1rem;">
      <img src="/immutable/img/theme-preview-light.png" style="width:100%; border-radius: var(--radius-md);" alt="Light Theme Preview">
      <p style="margin-bottom: 0; margin-top: 1rem; font-weight: 600; color: var(--fg-0);">Light</p>
    </Card>
  </a>
</div>

<h3 style="margin-top: 0; margin-bottom: 1rem;">Date & Time</h3>
<div style="display: flex; gap: 1rem; flex-wrap: wrap;">
    <a href="/settings/date-time-format?clear=true" style="text-decoration: none;">
        <Button variant={data?.dateTimeFormatHours != '24' && data?.dateTimeFormatHours != '12' ? 'primary' : 'secondary'}>
            {#if data?.dateTimeFormatHours != '24' && data?.dateTimeFormatHours != '12'}<IconCheckmark />{/if}
            Auto
        </Button>
    </a>
    <a href="/settings/date-time-format?h=24" style="text-decoration: none;">
        <Button variant={data?.dateTimeFormatHours == '24' ? 'primary' : 'secondary'}>
            {#if data?.dateTimeFormatHours == '24'}<IconCheckmark />{/if}
            24 Hour
        </Button>
    </a>
    <a href="/settings/date-time-format?h=12" style="text-decoration: none;">
        <Button variant={data?.dateTimeFormatHours == '12' ? 'primary' : 'secondary'}>
            {#if data?.dateTimeFormatHours == '12'}<IconCheckmark />{/if}
            12 Hour (AM/PM)
        </Button>
    </a>
</div>
