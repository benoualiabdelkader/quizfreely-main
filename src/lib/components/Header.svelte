<script>
  import Searchbar from "$lib/components/Searchbar.svelte";
  import { page } from "$app/state";
  import { beforeNavigate } from "$app/navigation";
  import { slide } from "svelte/transition";
  import IconUser from "$lib/icons/User.svelte";
  import IconMenu from "$lib/icons/Menu.svelte";
  import IconCloseXMark from "$lib/icons/CloseXMark.svelte";
  import Dropdown from "$lib/components/Dropdown.svelte";
  import Card from "$lib/components/ui/Card.svelte";

  beforeNavigate(function (navigation) {
    const toggle = document.getElementById("nav-menu-toggle");
    if (toggle) toggle.checked = false;
  });
</script>

<header
  class="navbar with-search with-status"
  transition:slide={{ duration: 400 }}
>
  <div class="menu">
    <input type="checkbox" id="nav-menu-toggle" class="nav-menu-toggle" aria-expanded="false" aria-controls="nav-menu-id" />
    <label for="nav-menu-toggle" class="nav-menu-open" aria-label="Toggle navigation menu">
      <IconMenu width="1.2rem" height="1.2rem" />
    </label>
    <label for="nav-menu-toggle" class="nav-menu-close" aria-label="Close navigation menu">
      <IconCloseXMark width="1.4rem" height="1.4rem" />
    </label>
    <div class="nav-menu" id="nav-menu-id">
      <div class={page.data?.header?.activePage == "home" ? "current" : ""}>
        <a href="/home">Home</a>
      </div>
      <div class={page.data?.header?.activePage == "explore" ? "current" : ""}>
        <a href="/explore">Explore</a>
      </div>
      {#if page.data?.authed}
      <div class={page.data?.header?.activePage == "dashboard" ? "current" : ""}>
        <a href="/dashboard">Dashboard</a>
      </div>
      {/if}
      <div class={page.data?.header?.activePage == "settings" ? "current" : ""}>
        <a href="/settings">Settings</a>
      </div>
    </div>
  </div>
  <div class="search">
    <Searchbar query={page.data?.header?.searchQuery} />
  </div>
  <div class="status">
    {#if page.data?.authed}
      <Dropdown
        container={{ style: "margin-right: 1rem; display: flex;" }}
        button={{ class: "btn btn-ghost btn-sm", "aria-label": "User menu" }}
        div={{ style: "margin-top: 0.5rem;" }}
      >
        {#snippet buttonContent()}
          <IconUser />
          <span class="hide-on-mobile-for-compactness">
            {page.data.authedUser.displayName.length < 10
              ? page.data.authedUser.displayName
              : "Signed in"}
          </span>
        {/snippet}
        {#snippet divContent(hide)}
          <Card class="user-dropdown-card">
            <a href="/users/{page.data.authedUser?.id}" class="btn btn-secondary btn-md" onclick={hide}>Profile</a>
            <a href="/settings" class="btn btn-secondary btn-md" onclick={hide}>Settings</a>
          </Card>
        {/snippet}
      </Dropdown>
    {:else if page.data?.header?.showSignUpLink}
      <div class="flex" style="margin-right:1rem">
        <a href="/sign-up" class="btn btn-secondary btn-sm">Sign up</a>
      </div>
    {:else}
      <div class="flex" style="margin-right:1rem">
        <a href="/sign-in" class="btn btn-secondary btn-sm">Sign in</a>
      </div>
    {/if}
  </div>
</header>

<style>
  .nav-menu > div {
    transition-duration: 0.4s;
  }
  .current {
    transition-duration: 0.4s;
  }
  .hide-on-mobile-for-compactness {
    margin-top: 0px;
  }
  @media only screen and (max-width: 800px) {
    .hide-on-mobile-for-compactness {
      display: none;
    }
  }
  
  :global(.user-dropdown-card) {
    padding: 1rem !important;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    min-width: 150px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.3) !important;
  }
  :global(.user-dropdown-card a) {
    text-align: left;
    justify-content: flex-start !important;
  }
</style>
