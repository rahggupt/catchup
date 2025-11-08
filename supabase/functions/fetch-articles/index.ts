// Supabase Edge Function to fetch articles from RSS feeds
// Deploy this to: supabase functions deploy fetch-articles

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// RSS Feed URLs for each source
const RSS_FEEDS = {
  'Wired': 'https://www.wired.com/feed/rss',
  'TechCrunch': 'https://techcrunch.com/feed/',
  'MIT Tech Review': 'https://www.technologyreview.com/feed/',
  'The Guardian': 'https://www.theguardian.com/technology/rss',
  'BBC Science': 'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml',
  'Ars Technica': 'https://feeds.arstechnica.com/arstechnica/index',
  'The Verge': 'https://www.theverge.com/rss/index.xml',
}

interface RSSItem {
  title: string
  link: string
  description: string
  pubDate: string
  author?: string
  category?: string[]
}

async function parseRSS(url: string): Promise<RSSItem[]> {
  try {
    const response = await fetch(url)
    const text = await response.text()
    
    // Simple XML parsing (in production, use a proper XML parser)
    const items: RSSItem[] = []
    const itemMatches = text.matchAll(/<item>([\s\S]*?)<\/item>/g)
    
    for (const match of itemMatches) {
      const itemXML = match[1]
      
      const title = itemXML.match(/<title><!\[CDATA\[(.*?)\]\]><\/title>|<title>(.*?)<\/title>/)?.[1] || ''
      const link = itemXML.match(/<link>(.*?)<\/link>/)?.[1] || ''
      const description = itemXML.match(/<description><!\[CDATA\[(.*?)\]\]><\/description>|<description>(.*?)<\/description>/)?.[1] || ''
      const pubDate = itemXML.match(/<pubDate>(.*?)<\/pubDate>/)?.[1] || ''
      const author = itemXML.match(/<dc:creator><!\[CDATA\[(.*?)\]\]><\/dc:creator>|<author>(.*?)<\/author>/)?.[1] || ''
      
      items.push({ title, link, description, pubDate, author })
    }
    
    return items
  } catch (error) {
    console.error(`Error parsing RSS from ${url}:`, error)
    return []
  }
}

function extractTopic(title: string, description: string, categories?: string[]): string {
  const text = `${title} ${description}`.toLowerCase()
  
  if (text.includes('ai') || text.includes('artificial intelligence') || text.includes('machine learning')) return '#AI'
  if (text.includes('climate') || text.includes('environment') || text.includes('carbon')) return '#Climate'
  if (text.includes('space') || text.includes('mars') || text.includes('nasa')) return '#Science'
  if (text.includes('policy') || text.includes('regulation') || text.includes('government')) return '#Politics'
  if (text.includes('startup') || text.includes('funding') || text.includes('investment')) return '#Business'
  if (text.includes('crypto') || text.includes('blockchain') || text.includes('bitcoin')) return '#Crypto'
  
  return '#Tech'
}

function getImagePlaceholder(source: string): string {
  const images = {
    'Wired': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
    'TechCrunch': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
    'MIT Tech Review': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80',
    'The Guardian': 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&q=80',
    'BBC Science': 'https://images.unsplash.com/photo-1614728423169-3f65fd722b7e?w=800&q=80',
    'Ars Technica': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800&q=80',
    'The Verge': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&q=80',
  }
  return images[source] || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&q=80'
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { timeFilter = '24h', userId } = await req.json()

    // Get user's active sources
    const { data: sources, error: sourcesError } = await supabaseClient
      .from('sources')
      .select('*')
      .eq('user_id', userId)
      .eq('active', true)

    if (sourcesError) throw sourcesError

    const articlesToInsert = []

    // Fetch articles from each active source
    for (const source of sources || []) {
      const feedUrl = RSS_FEEDS[source.name]
      if (!feedUrl) continue

      console.log(`Fetching from ${source.name}: ${feedUrl}`)
      const items = await parseRSS(feedUrl)

      // Filter by time
      const now = new Date()
      const cutoffTime = new Date()
      if (timeFilter === '2h') {
        cutoffTime.setHours(now.getHours() - 2)
      } else if (timeFilter === '24h') {
        cutoffTime.setHours(now.getHours() - 24)
      } else if (timeFilter === '7d') {
        cutoffTime.setDate(now.getDate() - 7)
      }

      for (const item of items) {
        const pubDate = new Date(item.pubDate)
        if (pubDate < cutoffTime) continue

        // Check if article already exists
        const { data: existing } = await supabaseClient
          .from('articles')
          .select('id')
          .eq('url', item.link)
          .single()

        if (existing) continue // Skip duplicates

        const topic = extractTopic(item.title, item.description)
        
        articlesToInsert.push({
          title: item.title.substring(0, 200),
          summary: item.description.substring(0, 500).replace(/<[^>]*>/g, ''),
          source: source.name,
          author: item.author || 'Staff Writer',
          topic: topic,
          url: item.link,
          image_url: getImagePlaceholder(source.name),
          published_at: item.pubDate,
        })
      }
    }

    // Insert articles in batch
    if (articlesToInsert.length > 0) {
      const { data: inserted, error: insertError } = await supabaseClient
        .from('articles')
        .insert(articlesToInsert)
        .select()

      if (insertError) throw insertError

      return new Response(
        JSON.stringify({
          success: true,
          articlesAdded: inserted?.length || 0,
          articles: inserted,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        articlesAdded: 0,
        message: 'No new articles found',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

